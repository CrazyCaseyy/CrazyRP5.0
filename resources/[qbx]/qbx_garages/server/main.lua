local logger = require '@qbx_core.modules.logger'

assert(lib.checkDependency('qbx_core', '1.19.0', true))
assert(lib.checkDependency('qbx_vehicles', '1.3.1', true))
lib.versionCheck('Qbox-project/qbx_garages')

---@class ErrorResult
---@field code string
---@field message string

---@class PlayerVehicle
---@field id number
---@field citizenid? string
---@field modelName string
---@field garage string
---@field state VehicleState
---@field depotPrice integer
---@field props table ox_lib properties table

Config = require 'config.server'
VEHICLES = exports.qbx_core:GetVehiclesByName()
Storage = require 'server.storage'
---@type table<string, GarageConfig>
Garages = Config.garages

lib.callback.register('qbx_garages:server:getGarages', function()
    return Garages
end)

---Returns garages for use server side.
local function getGarages()
    return Garages
end
exports('GetGarages', getGarages)

---@param name string
---@param config GarageConfig
local function registerGarage(name, config)
    Garages[name] = config
    TriggerClientEvent('qbx_garages:client:garageRegistered', -1, name, config)
    TriggerEvent('qbx_garages:server:garageRegistered', name, config)
end

exports('RegisterGarage', registerGarage)

---Sets the vehicle's garage. It is the caller's responsibility to make sure the vehicle is not currently spawned in the world, or else this may have no effect.
---@param vehicleId integer
---@param garageName string
---@return boolean success, ErrorResult?
local function setVehicleGarage(vehicleId, garageName)
    local garage = Garages[garageName]
    if not garage then
        return false, {
            code = 'not_found',
            message = string.format('garage name %s not found. Did you forget to register it?', garageName)
        }
    end

    local state = garage.type == GarageType.DEPOT and VehicleState.IMPOUNDED or VehicleState.GARAGED
    local numRowsAffected = Storage.setVehicleGarage(vehicleId, garageName, state)
    if numRowsAffected == 0 then
        return false, {
            code = 'no_rows_changed',
            message = string.format('no rows were changed for vehicleId=%s', vehicleId)
        }
    end
    return true
end

exports('SetVehicleGarage', setVehicleGarage)

---Sets the vehicle's price for retrieval at a depot. Only affects vehicles that are OUT or IMPOUNDED.
---@param vehicleId integer
---@param depotPrice integer
---@return boolean success, ErrorResult?
local function setVehicleDepotPrice(vehicleId, depotPrice)
    local numRowsAffected = Storage.setVehicleDepotPrice(vehicleId, depotPrice)
    if numRowsAffected == 0 then
        return false, {
            code = 'no_rows_changed',
            message = string.format('no rows were changed for vehicleId=%s', vehicleId)
        }
    end
    return true
end

exports('SetVehicleDepotPrice', setVehicleDepotPrice)

function FindPlateOnServer(plate)
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        if plate == GetVehicleNumberPlateText(vehicles[i]) then
            return true
        end
    end
end

---@param garage string
---@return GarageType?
function GetGarageType(garage)
    return Garages[garage]?.type
end

---@class PlayerVehiclesFilters
---@field citizenid? string
---@field states? VehicleState|VehicleState[]
---@field garage? string

---@param source number
---@param garageName string
---@return PlayerVehiclesFilters
function GetPlayerVehicleFilter(source, garageName)
    local player = exports.qbx_core:GetPlayer(source)
    local garage = Garages[garageName]
    local filter = {}
    -- OUT is included by default (not just GARAGED) so a vehicle that's
    -- left out and gone missing still shows up in the list - client/main.lua
    -- displays it as "already out"/offers the paid Recover option instead
    -- of Take Out or Transfer Here for anything not GARAGED, so this can't
    -- let someone take out or transfer a vehicle that's still out.
    -- IMPOUNDED is deliberately left out of this default - that one's
    -- meant to force an actual trip to a depot/impound lot (its own
    -- explicit `states` override), not show up everywhere. A garage with
    -- its own `states` override (the depots) is untouched either way.
    filter.states = garage.states or { VehicleState.GARAGED, VehicleState.OUT }

    if garage.fleet then
        -- Department-owned pool, not personal vehicles - scoped to both
        -- the fleet's placeholder citizen AND this specific garage (unlike
        -- personal garages below), since a fleet vehicle only ever belongs
        -- to the one motor pool it was bought into, not "wherever the
        -- owner's other cars happen to be" - see server/fleet.lua.
        filter.citizenid = FLEET_OWNER_CITIZENID
        filter.garage = garageName
        return filter
    end

    filter.citizenid = not garage.shared and player.PlayerData.citizenid or nil
    -- Every non-fleet garage lists the full fleet (matching type/state),
    -- not just whichever vehicles happen to be registered to this
    -- specific one - garageName is still tracked per-vehicle (updated in
    -- spawn-vehicle.lua whenever one's taken out from somewhere new), it
    -- just no longer restricts what shows up where. skipGarageCheck on
    -- individual garages (impound lots) is redundant now but left alone
    -- rather than ripped out for a one-line behavior change.
    filter.garage = nil
    return filter
end

---@param source number
---@param garageName string
---@return GarageConfig?
function TryGetGarage(source, garageName)
    local garage = Garages[garageName]
    if garage then return garage end

    logger.log({
        source = source,
        event = 'error',
        message = string.format(
            'Attempted to spawn a vehicle from a non-existent garage: %s',
            garageName
        ),
        webhook = Config.logging.webhook.error,
        color = 'red'
    })
end

local function getCanAccessGarage(player, garage)
    if garage.groups and not exports.qbx_core:HasPrimaryGroup(player.PlayerData.source, garage.groups) then
        return false
    end
    if garage.canAccess ~= nil and not garage.canAccess(player.PlayerData.source) then
        return false
    end
    return true
end

---@param playerVehicle PlayerVehicle
---@return VehicleType
local function getVehicleType(playerVehicle)
    local vehicleData = VEHICLES[playerVehicle.modelName]

    -- Addon vehicles have no entry here (qbx_core's shared/vehicles.lua
    -- only knows the base game) - default to CAR rather than indexing into
    -- nil. Fine for this fallback's purpose: it only matters for non-fleet
    -- garages (fleet garages skip this check entirely, see
    -- getGarageVehicles), where getting an addon boat/heli's category
    -- wrong just means it shows up filed under the wrong garage type
    -- instead of erroring.
    if not vehicleData then
        return VehicleType.CAR
    end

    if vehicleData.category == 'helicopters' or vehicleData.category == 'planes' then
        return VehicleType.AIR
    elseif vehicleData.category == 'boats' then
        return VehicleType.SEA
    else
        return VehicleType.CAR
    end
end

---@param source number
---@param garageName string
---@return PlayerVehicle[]?
lib.callback.register('qbx_garages:server:getGarageVehicles', function(source, garageName)
    local player = exports.qbx_core:GetPlayer(source)
    local garage = TryGetGarage(source, garageName)
    if not garage then return end
    if not getCanAccessGarage(player, garage) then return end
    local filter = GetPlayerVehicleFilter(source, garageName)
    local playerVehicles = exports.qbx_vehicles:GetPlayerVehicles(filter)
    local toSend = {}
    if not playerVehicles[1] then return end

    local vehicleType = garage.vehicleType
    for _, vehicle in pairs(playerVehicles) do
        if not FindPlateOnServer(vehicle.props.plate) then
            -- Fleet garages skip the type check entirely - the filter above
            -- (GetPlayerVehicleFilter) already scoped playerVehicles down
            -- to exactly this garage's own fleet pool, so there's nothing
            -- else in the list it could need filtering against. That also
            -- sidesteps needing to resolve an addon vehicle's type at all,
            -- which getVehicleType can't do reliably for one qbx_core's
            -- registry has never heard of.
            if garage.fleet or vehicleType == getVehicleType(vehicle) then
                OverrideFreeDepotPriceForOutVehicle(vehicle)

                -- Fleet vehicles show who they're currently assigned to
                -- (or that nobody is) so an officer can see the whole
                -- fleet, not just their own vehicle, without being able to
                -- take out ones that aren't theirs - see server/fleet.lua.
                if garage.fleet then
                    local assignment = GetFleetAssignment(vehicle.id)
                    vehicle.fleetAssignedCitizenid = assignment and assignment.citizenid or nil
                    vehicle.fleetAssignedName = assignment and assignment.name or nil
                end

                toSend[#toSend + 1] = vehicle
            end
        end
    end
    return toSend
end)

-- Relocates a GARAGED vehicle's registered home to a different garage for
-- a flat fee, as its own explicit step - a garage's vehicle list shows
-- everything a player owns regardless of where it's actually registered
-- (see GetPlayerVehicleFilter above), but spawn-vehicle.lua's spawnVehicle
-- still only lets you take a vehicle out of the garage it's actually
-- registered to, so this (and only this) is what changes that. Once this
-- succeeds, taking the vehicle out from here is a separate follow-up
-- action in the UI (client/main.lua re-opens the vehicle list so the
-- player clicks back in and sees "Take Out" for real this time), not
-- something this callback does itself.
---@param source number
---@param vehicleId integer
---@param garageName string
---@return boolean
lib.callback.register('qbx_garages:server:transferVehicle', function(source, vehicleId, garageName)
    local garage = TryGetGarage(source, garageName)
    if not garage or garage.type == GarageType.DEPOT then return false end

    local player = exports.qbx_core:GetPlayer(source)
    if not getCanAccessGarage(player, garage) then
        exports.qbx_core:Notify(source, locale('error.no_access'), 'error')
        return false
    end

    local filter = GetPlayerVehicleFilter(source, garageName)
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId, filter)
    if not playerVehicle or playerVehicle.state ~= VehicleState.GARAGED then
        exports.qbx_core:Notify(source, locale('error.not_owned'), 'error')
        return false
    end
    if getVehicleType(playerVehicle) ~= garage.vehicleType then
        exports.qbx_core:Notify(source, locale('error.not_correct_type'), 'error')
        return false
    end
    if playerVehicle.garage == garageName then return false end -- already here, nothing to do

    local canPay = payDepotPrice(player, TRANSFER_FEE)
    if not canPay then
        exports.qbx_core:Notify(source, locale('error.not_enough'), 'error')
        return false
    end

    setVehicleGarage(vehicleId, garageName)
    exports.qbx_core:Notify(source, locale('success.vehicle_transferred', lib.math.groupdigits(TRANSFER_FEE)), 'success')
    return true
end)

-- Lets a player pay to get a vehicle that's OUT but nowhere to be found
-- (left behind, despawned, crashed out of existence, whatever) straight
-- back into one of their garages, instead of the only recovery option
-- being a depot/impound lot. Fleet vehicles are exempt - those already put
-- themselves back for free the moment their entity actually despawns (see
-- qbx_garages/server/fleet.lua's entityRemoved handler), and this is a
-- personal-vehicle feature.
local RECOVERY_FEE = 500

---@param source number
---@param vehicleId integer
---@param garageName string
---@return boolean
lib.callback.register('qbx_garages:server:recoverVehicle', function(source, vehicleId, garageName)
    local garage = TryGetGarage(source, garageName)
    if not garage or garage.type == GarageType.DEPOT or garage.fleet then return false end

    local player = exports.qbx_core:GetPlayer(source)
    if not getCanAccessGarage(player, garage) then
        exports.qbx_core:Notify(source, locale('error.no_access'), 'error')
        return false
    end

    local filter = GetPlayerVehicleFilter(source, garageName)
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId, filter)
    if not playerVehicle or playerVehicle.state ~= VehicleState.OUT then
        exports.qbx_core:Notify(source, locale('error.not_owned'), 'error')
        return false
    end

    -- Re-checked server-side regardless of what the client saw - a vehicle
    -- that's still physically sitting somewhere in the world has to be
    -- found (or actually despawn first), not paid back into storage out
    -- from under whoever's driving it.
    if FindPlateOnServer(playerVehicle.props.plate) then
        exports.qbx_core:Notify(source, 'That vehicle is still out in the world - find it, or wait for it to despawn first.', 'error')
        return false
    end

    local canPay = payDepotPrice(player, RECOVERY_FEE)
    if not canPay then
        exports.qbx_core:Notify(source, locale('error.not_enough'), 'error')
        return false
    end

    setVehicleGarage(vehicleId, garageName)
    exports.qbx_core:Notify(source, ('Paid $%s to recover your vehicle.'):format(lib.math.groupdigits(RECOVERY_FEE)), 'success')
    return true
end)

---@param source number
---@param vehicleId string
---@param garageName string
---@return boolean
local function isParkable(source, vehicleId, garageName)
    local garageType = GetGarageType(garageName)
    --- DEPOTS are only for retrieving, not storing
    if garageType == GarageType.DEPOT then return false end
    if not vehicleId then return false end
    local player = exports.qbx_core:GetPlayer(source)
    local garage = Garages[garageName]
    if not getCanAccessGarage(player, garage) then
        return false
    end
    ---@type PlayerVehicle
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if getVehicleType(playerVehicle) ~= garage.vehicleType then
        return false
    end

    if garage.fleet then
        -- Storing it back doesn't require it to still be assigned to you
        -- (only taking one OUT does, see spawn-vehicle.lua) - just that
        -- it's genuinely one of this fleet's vehicles, not owned by any
        -- real citizenid at all. Without this branch the check below
        -- always fails for fleet vehicles (their citizenid is the fleet
        -- placeholder, never the officer's own), so nobody could ever
        -- park one back.
        return playerVehicle.citizenid == FLEET_OWNER_CITIZENID
    end

    if not garage.shared then
        if playerVehicle.citizenid ~= player.PlayerData.citizenid then
            return false
        end
    end
    return true
end

lib.callback.register('qbx_garages:server:isParkable', function(source, garage, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local vehicleId = Entity(vehicle).state.vehicleid or exports.qbx_vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(vehicle))
    return isParkable(source, vehicleId, garage)
end)

---@param source number
---@param netId number
---@param props table ox_lib vehicle props https://github.com/communityox/ox_lib/blob/master/resource/vehicleProperties/client.lua#L3
---@param garage string
lib.callback.register('qbx_garages:server:parkVehicle', function(source, netId, props, garage)
    assert(Garages[garage] ~= nil, string.format('Garage %s not found. Did you register this garage?', garage))
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local vehicleId = Entity(vehicle).state.vehicleid or exports.qbx_vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(vehicle))
    local owned = isParkable(source, vehicleId, garage) --Check ownership
    if not owned then
        exports.qbx_core:Notify(source, locale('error.not_owned'), 'error')
        return
    end

    exports.qbx_vehicles:SaveVehicle(vehicle, {
        garage = garage,
        state = VehicleState.GARAGED,
        props = props
    })

    exports.qbx_core:DeleteVehicle(vehicle)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    Wait(100)
    if Config.autoRespawn then
        Storage.moveOutVehiclesIntoGarages()
    end
end)