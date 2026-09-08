-- Police fleet: department-owned vehicles (the 'policefleet' garage in
-- config/server.lua, fleet = true) instead of personal ones. Every fleet
-- vehicle's player_vehicles.citizenid is this placeholder character below
-- (not a real player) so GetPlayerVehicleFilter (server/main.lua) can
-- scope the fleet garage's vehicle list to exactly this pool, the same way
-- a real citizenid scopes a personal one. On top of that, each vehicle
-- still needs its own row here in police_fleet_assignments before any
-- specific officer can actually take it out - being on the fleet roster
-- and being ABLE to drive one of its cars are two separate things.

FLEET_OWNER_CITIZENID = 'FLEETPD01'

local STARTER_FLEET = {
    { model = 'police', plate = 'PD-001' },
    { model = 'police', plate = 'PD-002' },
    { model = 'police2', plate = 'PD-003' },
}

local ready = false

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `police_fleet_assignments` (
            `vehicle_id` int(11) NOT NULL,
            `citizenid` varchar(50) NOT NULL,
            `name` varchar(100) NOT NULL,
            `assigned_by` varchar(100) NOT NULL,
            `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`vehicle_id`),
            CONSTRAINT `fk_fleet_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `player_vehicles` (`id`) ON DELETE CASCADE
        )
    ]])

    -- Placeholder "character" the fleet's vehicles are registered to -
    -- player_vehicles.citizenid has a foreign key against players.citizenid,
    -- so a department-owned car still needs a real row there even though
    -- nobody ever actually plays this "character". name/charinfo/etc are
    -- just enough to satisfy the schema, not meant to be seen anywhere.
    local exists = MySQL.scalar.await('SELECT 1 FROM `players` WHERE `citizenid` = ?', { FLEET_OWNER_CITIZENID })
    if not exists then
        MySQL.insert.await([[
            INSERT INTO `players` (`citizenid`, `license`, `name`, `money`, `charinfo`, `job`, `gang`, `position`, `metadata`, `inventory`)
            VALUES (?, ?, ?, '{}', '{}', '{}', '{}', '{"x":0.0,"y":0.0,"z":0.0,"w":0.0}', '{}', '[]')
        ]], { FLEET_OWNER_CITIZENID, 'FLEET-PLACEHOLDER-NO-LOGIN', 'Police Fleet' })
    end

    -- One-time seed of the starter fleet, same "already stocked?" guard as
    -- the armoury seeding used to use - never re-adds on a later restart.
    local fleetCount = MySQL.scalar.await('SELECT COUNT(*) FROM `player_vehicles` WHERE `citizenid` = ?', { FLEET_OWNER_CITIZENID })
    if fleetCount == 0 then
        for _, entry in ipairs(STARTER_FLEET) do
            local hash = GetHashKey(entry.model)
            local props = {
                model = hash,
                plate = entry.plate,
                engineHealth = 1000,
                bodyHealth = 1000,
                fuelLevel = 100,
            }

            MySQL.insert.await([[
                INSERT INTO `player_vehicles` (`citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`, `depotprice`)
                VALUES (?, ?, ?, ?, ?, 'policefleet', 100, 1000, 1000, 1, 0)
            ]], { FLEET_OWNER_CITIZENID, entry.model, tostring(hash), json.encode(props), entry.plate })
        end

        print(('[qbx_garages] Police fleet seeded with %d vehicles.'):format(#STARTER_FLEET))
    end

    ready = true
end)

---@param vehicleId integer
---@return { citizenid: string, name: string }?
function GetFleetAssignment(vehicleId)
    return MySQL.single.await('SELECT `citizenid`, `name` FROM `police_fleet_assignments` WHERE `vehicle_id` = ?', { vehicleId })
end

exports('GetFleetAssignment', GetFleetAssignment)

-- If a fleet vehicle's entity gets removed (wrecked/exploded, an admin
-- despawning it, network desync, etc) while it's still marked OUT, nothing
-- else on this server would ever put it back - qbx_core's own
-- vehicle-persistence system would normally react to a deleted vehicle,
-- but it RESPAWNS it in place rather than returning it to the garage, and
-- it's disabled server-wide anyway (qbx:enableVehiclePersistence,
-- server.cfg). So instead: whenever any vehicle is removed, if it's a
-- fleet vehicle still marked OUT, just flip it back to GARAGED - no
-- respawn, it's simply back on the lot for the next officer to pull out.
-- Vehicles stored properly through the normal UI (main.lua's storeVehicle,
-- which sets GARAGED before deleting the entity) are already GARAGED by
-- the time this fires, so this is a no-op for that path.
AddEventHandler('entityRemoved', function(entity)
    local vehicleId = Entity(entity).state.vehicleid
    if not vehicleId then return end

    local vehicle = MySQL.single.await('SELECT `state` FROM `player_vehicles` WHERE `id` = ? AND `citizenid` = ?', { vehicleId, FLEET_OWNER_CITIZENID })
    if not vehicle or vehicle.state ~= VehicleState.OUT then return end

    MySQL.update.await('UPDATE `player_vehicles` SET `state` = ?, `depotprice` = 0 WHERE `id` = ?', { VehicleState.GARAGED, vehicleId })
end)

---@param source number
---@return boolean
local function isFleetBoss(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    return player.PlayerData.job.name == 'police' and player.PlayerData.job.isboss == true
end

exports('IsFleetBoss', isFleetBoss)

-- Shared by both the /assignfleet command and qbx_police's UI
-- (qbx_garages:server:assignFleetVehicle callback below) - one place that
-- actually writes an assignment, so both entry points stay in sync.
---@param source number the boss doing the assigning
---@param vehicleId integer
---@param targetId number the officer's server id
---@return boolean success, string? error, string? plate, string? name
local function assignFleetVehicle(source, vehicleId, targetId)
    if not isFleetBoss(source) then
        return false, 'You need to be a police boss to do that.'
    end

    local target = exports.qbx_core:GetPlayer(targetId)
    if not target then
        return false, 'Invalid player.'
    end
    if target.PlayerData.job.name ~= 'police' then
        return false, 'That player is not police.'
    end

    local vehicle = MySQL.single.await('SELECT `plate` FROM `player_vehicles` WHERE `id` = ? AND `citizenid` = ?', { vehicleId, FLEET_OWNER_CITIZENID })
    if not vehicle then
        return false, 'Not a fleet vehicle.'
    end

    local name = ('%s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname)
    MySQL.query.await([[
        INSERT INTO `police_fleet_assignments` (`vehicle_id`, `citizenid`, `name`, `assigned_by`)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `citizenid` = VALUES(`citizenid`), `name` = VALUES(`name`), `assigned_by` = VALUES(`assigned_by`), `assigned_at` = CURRENT_TIMESTAMP
    ]], { vehicleId, target.PlayerData.citizenid, name, GetPlayerName(source) })

    return true, nil, vehicle.plate, name
end

---@param source number the boss doing the unassigning
---@param vehicleId integer
---@return boolean success, string? error, string? plate
local function unassignFleetVehicle(source, vehicleId)
    if not isFleetBoss(source) then
        return false, 'You need to be a police boss to do that.'
    end

    local vehicle = MySQL.single.await('SELECT `plate` FROM `player_vehicles` WHERE `id` = ? AND `citizenid` = ?', { vehicleId, FLEET_OWNER_CITIZENID })
    if not vehicle then
        return false, 'Not a fleet vehicle.'
    end

    MySQL.query.await('DELETE FROM `police_fleet_assignments` WHERE `vehicle_id` = ?', { vehicleId })
    return true, nil, vehicle.plate
end

local PLATE_CHARS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'

---@return string
local function generateFleetPlate()
    -- PD + 6 random alphanumeric chars = 8 total, the same max length as a
    -- normal generated plate. Re-rolls on collision rather than continuing
    -- a counter, since plate is globally unique on player_vehicles.
    while true do
        local suffix = {}
        for i = 1, 6 do
            local index = math.random(1, #PLATE_CHARS)
            suffix[i] = PLATE_CHARS:sub(index, index)
        end
        local plate = 'PD' .. table.concat(suffix)

        local taken = MySQL.scalar.await('SELECT 1 FROM `player_vehicles` WHERE `plate` = ?', { plate })
        if not taken then return plate end
    end
end

---@param source number the boss adding it
---@param model string
---@return boolean success, string? error, string? plate
local function addFleetVehicle(source, model)
    if not isFleetBoss(source) then
        return false, 'You need to be a police boss to do that.'
    end

    model = model:lower()

    -- exports.qbx_core:GetVehiclesByName() only knows the vehicles baked
    -- into qbx_core's own shared/vehicles.lua - real for the base game, but
    -- it has no idea an addon car even exists, so it rejected every addon
    -- police vehicle. IsModelInCdimage/IsModelAVehicle are the natives
    -- that actually know (work for addon models too, as long as the
    -- resource adding them is running), but they're CLIENT-ONLY - this
    -- file is entirely server-side, so ask the boss's own client (source
    -- is them either way, whether this came from the /addfleetvehicle
    -- command or the UI callback) to check locally instead.
    if not lib.callback.await('qbx_garages:client:isValidVehicleModel', source, model) then
        return false, ('"%s" is not a real vehicle model.'):format(model)
    end

    local plate = generateFleetPlate()
    local hash = GetHashKey(model)
    local props = {
        model = hash,
        plate = plate,
        engineHealth = 1000,
        bodyHealth = 1000,
        fuelLevel = 100,
    }

    MySQL.insert.await([[
        INSERT INTO `player_vehicles` (`citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `fuel`, `engine`, `body`, `state`, `depotprice`)
        VALUES (?, ?, ?, ?, ?, 'policefleet', 100, 1000, 1000, 1, 0)
    ]], { FLEET_OWNER_CITIZENID, model, tostring(hash), json.encode(props), plate })

    return true, nil, plate
end

---@param source number the boss deleting it
---@param vehicleId integer
---@return boolean success, string? error, string? plate
local function deleteFleetVehicle(source, vehicleId)
    if not isFleetBoss(source) then
        return false, 'You need to be a police boss to do that.'
    end

    local vehicle = MySQL.single.await('SELECT `plate`, `state` FROM `player_vehicles` WHERE `id` = ? AND `citizenid` = ?', { vehicleId, FLEET_OWNER_CITIZENID })
    if not vehicle then
        return false, 'Not a fleet vehicle.'
    end

    -- OUT (0) means it's currently spawned/being driven somewhere -
    -- deleting the DB row out from under a live vehicle would leave an
    -- orphaned entity in the world with nothing backing it. It has to be
    -- parked (GARAGED) first. police_fleet_assignments cascades on its own
    -- FK, so no separate cleanup needed for that part.
    if vehicle.state == 0 then
        return false, 'That vehicle is currently out - it needs to be parked before it can be removed from the fleet.'
    end

    MySQL.query.await('DELETE FROM `player_vehicles` WHERE `id` = ?', { vehicleId })
    return true, nil, vehicle.plate
end

lib.addCommand('assignfleet', {
    help = 'Assign an available police fleet vehicle to an officer by model',
    params = {
        { name = 'target', type = 'playerId', help = 'The officer to assign it to' },
        { name = 'model', type = 'string', help = 'The fleet vehicle model, e.g. police' },
    },
}, function(source, args)
    while not ready do Wait(50) end

    -- First fleet vehicle of this model that doesn't already have a row in
    -- police_fleet_assignments - picked automatically rather than by plate,
    -- since the command is by model, not a specific physical car (the
    -- qbx_police UI lets a boss pick a specific one instead, see
    -- qbx_garages:server:getFleetRoster/assignFleetVehicle below).
    local vehicle = MySQL.single.await([[
        SELECT pv.id, pv.plate FROM `player_vehicles` pv
        LEFT JOIN `police_fleet_assignments` pfa ON pfa.vehicle_id = pv.id
        WHERE pv.citizenid = ? AND pv.vehicle = ? AND pfa.vehicle_id IS NULL
        LIMIT 1
    ]], { FLEET_OWNER_CITIZENID, args.model:lower() })
    if not vehicle then
        return exports.qbx_core:Notify(source, ('No available %s in the fleet.'):format(args.model), 'error')
    end

    local success, err, plate, name = assignFleetVehicle(source, vehicle.id, args.target)
    if not success then
        return exports.qbx_core:Notify(source, err, 'error')
    end

    exports.qbx_core:Notify(source, ('%s (%s) assigned to %s.'):format(args.model, plate, name), 'success')
end)

lib.addCommand('unassignfleet', {
    help = 'Remove a fleet vehicle\'s current assignment',
    params = {
        { name = 'plate', type = 'string', help = 'The fleet vehicle\'s plate' },
    },
}, function(source, args)
    while not ready do Wait(50) end

    local vehicle = MySQL.single.await('SELECT `id` FROM `player_vehicles` WHERE `plate` = ? AND `citizenid` = ?', { args.plate:upper(), FLEET_OWNER_CITIZENID })
    if not vehicle then
        return exports.qbx_core:Notify(source, 'No fleet vehicle with that plate.', 'error')
    end

    local success, err, plate = unassignFleetVehicle(source, vehicle.id)
    if not success then
        return exports.qbx_core:Notify(source, err, 'error')
    end

    exports.qbx_core:Notify(source, ('%s unassigned.'):format(plate), 'success')
end)

lib.addCommand('addfleetvehicle', {
    help = 'Add a new vehicle to the police fleet',
    params = {
        { name = 'model', type = 'string', help = 'The vehicle model, e.g. police' },
    },
}, function(source, args)
    while not ready do Wait(50) end

    local success, err, plate = addFleetVehicle(source, args.model)
    if not success then
        return exports.qbx_core:Notify(source, err, 'error')
    end

    exports.qbx_core:Notify(source, ('%s (%s) added to the fleet.'):format(args.model, plate), 'success')
end)

lib.addCommand('deletefleetvehicle', {
    help = 'Remove a vehicle from the police fleet (must be parked)',
    params = {
        { name = 'plate', type = 'string', help = 'The fleet vehicle\'s plate' },
    },
}, function(source, args)
    while not ready do Wait(50) end

    local vehicle = MySQL.single.await('SELECT `id` FROM `player_vehicles` WHERE `plate` = ? AND `citizenid` = ?', { args.plate:upper(), FLEET_OWNER_CITIZENID })
    if not vehicle then
        return exports.qbx_core:Notify(source, 'No fleet vehicle with that plate.', 'error')
    end

    local success, err, plate = deleteFleetVehicle(source, vehicle.id)
    if not success then
        return exports.qbx_core:Notify(source, err, 'error')
    end

    exports.qbx_core:Notify(source, ('%s removed from the fleet.'):format(plate), 'success')
end)

-- ============================================================
-- qbx_police's /fleetvehicle UI talks to these instead of duplicating any
-- of the above - kept in qbx_garages since this is where the fleet data
-- actually lives (player_vehicles, police_fleet_assignments).
-- ============================================================

---@param source number
---@return { id: integer, plate: string, model: string, assignedCitizenid: string?, assignedName: string? }[]
lib.callback.register('qbx_garages:server:getFleetRoster', function(source)
    while not ready do Wait(50) end
    if not isFleetBoss(source) then return {} end

    local rows = MySQL.query.await([[
        SELECT pv.id, pv.plate, pv.vehicle AS model, pfa.citizenid AS assignedCitizenid, pfa.name AS assignedName
        FROM `player_vehicles` pv
        LEFT JOIN `police_fleet_assignments` pfa ON pfa.vehicle_id = pv.id
        WHERE pv.citizenid = ?
        ORDER BY pv.vehicle, pv.plate
    ]], { FLEET_OWNER_CITIZENID }) or {}

    return rows
end)

---@param source number
---@param vehicleId integer
---@param targetId number
---@return boolean success, string? errorOrName
lib.callback.register('qbx_garages:server:assignFleetVehicle', function(source, vehicleId, targetId)
    local success, err, _, name = assignFleetVehicle(source, vehicleId, targetId)
    return success, success and name or err
end)

---@param source number
---@param vehicleId integer
---@return boolean success, string? error
lib.callback.register('qbx_garages:server:unassignFleetVehicle', function(source, vehicleId)
    local success, err = unassignFleetVehicle(source, vehicleId)
    return success, err
end)

---@param source number
---@param model string
---@return boolean success, string? errorOrPlate
lib.callback.register('qbx_garages:server:addFleetVehicle', function(source, model)
    while not ready do Wait(50) end
    local success, err, plate = addFleetVehicle(source, model)
    return success, success and plate or err
end)

---@param source number
---@param vehicleId integer
---@return boolean success, string? errorOrPlate
lib.callback.register('qbx_garages:server:deleteFleetVehicle', function(source, vehicleId)
    while not ready do Wait(50) end
    local success, err, plate = deleteFleetVehicle(source, vehicleId)
    return success, success and plate or err
end)
