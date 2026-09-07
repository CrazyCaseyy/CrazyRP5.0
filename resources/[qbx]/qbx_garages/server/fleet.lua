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

---@param source number
---@return boolean
local function isFleetBoss(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    return player.PlayerData.job.name == 'police' and player.PlayerData.job.isboss == true
end

lib.addCommand('assignfleet', {
    help = 'Assign an available police fleet vehicle to an officer by model',
    params = {
        { name = 'target', type = 'playerId', help = 'The officer to assign it to' },
        { name = 'model', type = 'string', help = 'The fleet vehicle model, e.g. police' },
    },
}, function(source, args)
    while not ready do Wait(50) end

    if not isFleetBoss(source) then
        return exports.qbx_core:Notify(source, 'You need to be a police boss to do that.', 'error')
    end

    local target = exports.qbx_core:GetPlayer(args.target)
    if not target then
        return exports.qbx_core:Notify(source, 'Invalid player.', 'error')
    end
    if target.PlayerData.job.name ~= 'police' then
        return exports.qbx_core:Notify(source, 'That player is not police.', 'error')
    end

    -- First fleet vehicle of this model that doesn't already have a row in
    -- police_fleet_assignments - picked automatically rather than by plate,
    -- since the boss is choosing a model, not a specific physical car.
    local vehicle = MySQL.single.await([[
        SELECT pv.id, pv.plate FROM `player_vehicles` pv
        LEFT JOIN `police_fleet_assignments` pfa ON pfa.vehicle_id = pv.id
        WHERE pv.citizenid = ? AND pv.vehicle = ? AND pfa.vehicle_id IS NULL
        LIMIT 1
    ]], { FLEET_OWNER_CITIZENID, args.model:lower() })
    if not vehicle then
        return exports.qbx_core:Notify(source, ('No available %s in the fleet.'):format(args.model), 'error')
    end

    local name = ('%s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname)
    MySQL.query.await([[
        INSERT INTO `police_fleet_assignments` (`vehicle_id`, `citizenid`, `name`, `assigned_by`)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `citizenid` = VALUES(`citizenid`), `name` = VALUES(`name`), `assigned_by` = VALUES(`assigned_by`), `assigned_at` = CURRENT_TIMESTAMP
    ]], { vehicle.id, target.PlayerData.citizenid, name, GetPlayerName(source) })

    exports.qbx_core:Notify(source, ('%s (%s) assigned to %s.'):format(args.model, vehicle.plate, name), 'success')
end)

lib.addCommand('unassignfleet', {
    help = 'Remove a fleet vehicle\'s current assignment',
    params = {
        { name = 'plate', type = 'string', help = 'The fleet vehicle\'s plate' },
    },
}, function(source, args)
    while not ready do Wait(50) end

    if not isFleetBoss(source) then
        return exports.qbx_core:Notify(source, 'You need to be a police boss to do that.', 'error')
    end

    local vehicle = MySQL.single.await('SELECT `id` FROM `player_vehicles` WHERE `plate` = ? AND `citizenid` = ?', { args.plate:upper(), FLEET_OWNER_CITIZENID })
    if not vehicle then
        return exports.qbx_core:Notify(source, 'No fleet vehicle with that plate.', 'error')
    end

    MySQL.query.await('DELETE FROM `police_fleet_assignments` WHERE `vehicle_id` = ?', { vehicle.id })
    exports.qbx_core:Notify(source, ('%s unassigned.'):format(args.plate:upper()), 'success')
end)
