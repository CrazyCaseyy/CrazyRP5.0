local logger = require '@qbx_core.modules.logger'

-- Flat fee for transferring a vehicle's registered garage to a different
-- one (main.lua's transferVehicle callback) - garages now list every
-- vehicle you own everywhere (see main.lua's GetPlayerVehicleFilter), so
-- this is what actually makes "which garage it's based at" mean something
-- again. Global (not local) - and so is payDepotPrice below - since
-- main.lua's transfer callback needs both too, and Lua's `local` at a
-- file's top level doesn't cross files within the same resource.
TRANSFER_FEE = 500

---@param vehicleId integer
---@param modelName string
local function setVehicleStateToOut(vehicleId, vehicle, modelName)
    local depotPrice = Config.calculateImpoundFee(vehicleId, modelName) or 0
    exports.qbx_vehicles:SaveVehicle(vehicle, {
        state = VehicleState.OUT,
        depotPrice = depotPrice,
    })
end

---@param player table
---@param depotPrice integer
function payDepotPrice(player, depotPrice)
    local cashBalance = player.PlayerData.money.cash
    local bankBalance = player.PlayerData.money.bank

    if cashBalance >= depotPrice then
        player.Functions.RemoveMoney('cash', depotPrice, 'paid-depot')
        return true
    elseif bankBalance >= depotPrice then
        player.Functions.RemoveMoney('bank', depotPrice, 'paid-depot')
        return true
    end
    return false
end

---@param source number
---@param vehicleId integer
---@param garageName string
---@param accessPointIndex integer
---@return number? netId
lib.callback.register('qbx_garages:server:spawnVehicle', function (source, vehicleId, garageName, accessPointIndex)
    local garage = TryGetGarage(source, garageName)
    if not garage then return end

    local accessPoint = garage.accessPoints[accessPointIndex]
    if not accessPoint then
        logger.log({
            source = source,
            message = string.format(
                'Attempted to spawn a vehicle from a non-existent access point index: %d for garage: %s',
                accessPointIndex,
                garageName
            ),
            webhook = Config.logging.webhook.error,
            event = 'error',
            color = 'red'
        })

        return
    end

    -- Anti-cheat distance check - kept a bit above the interact zone's own
    -- useRadius (now 3.0 on the public parking spots, config/server.lua)
    -- so someone legitimately standing at the edge of a bigger zone
    -- doesn't get flagged as suspicious for it.
    local distanceBetweenPlayerAndAccessPoint = #(GetEntityCoords(GetPlayerPed(source)) - accessPoint.coords.xyz)
    if distanceBetweenPlayerAndAccessPoint > 5 then
        logger.log({
            source = source,
            message = string.format(
                'Player attempted to spawn a vehicle but was too far from the access point. Distance: %.2f, Access Point Index: %d, Garage: %s',
                distanceBetweenPlayerAndAccessPoint,
                accessPointIndex,
                garageName
            ),
            webhook = Config.logging.webhook.anticheat,
            event = 'suspicious',
            color = 'white'
        })

        return
    end
    local garageType = GetGarageType(garageName)

    local spawnCoords = accessPoint.spawn or accessPoint.coords
    if Config.distanceCheck then
        local nearbyVehicle = lib.getClosestVehicle(spawnCoords.xyz, Config.distanceCheck, false)
        if nearbyVehicle then
            exports.qbx_core:Notify(source, locale('error.no_space'), 'error')
            return
        end
    end

    local filter = GetPlayerVehicleFilter(source, garageName)
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId, filter)
    if not playerVehicle then
        exports.qbx_core:Notify(source, locale('error.not_owned'), 'error')
        return
    end
    if garageType == GarageType.DEPOT and FindPlateOnServer(playerVehicle.props.plate) then -- If depot, check if vehicle is not already spawned on the map
        return exports.qbx_core:Notify(source, locale('error.not_impound'), 'error')
    end

    -- Impound retrieval is free (config.calculateImpoundFee always returns 0
    -- now), so skip the charge entirely rather than "charging" $0.
    if garageType == GarageType.DEPOT and playerVehicle.depotPrice and playerVehicle.depotPrice > 0 then
        local player = exports.qbx_core:GetPlayer(source)
        OverrideFreeDepotPriceForOutVehicle(playerVehicle)
        local canPay = payDepotPrice(player, playerVehicle.depotPrice)

        if not canPay then
            exports.qbx_core:Notify(source, locale('error.not_enough'), 'error')
            return
        end
    end

    -- Every garage lists all of a player's vehicles regardless of which
    -- one they're actually registered to (main.lua's
    -- GetPlayerVehicleFilter), but taking one out still requires it to
    -- actually be here first - main.lua's transferVehicle callback (a
    -- separate, explicit "Transfer Here" step in the UI, paid up front)
    -- is the only thing that changes a vehicle's registered garage now.
    -- Depots are exempt: every vehicle sitting in one is "not at its
    -- registered garage" by definition, that's just what recovering an
    -- OUT/IMPOUNDED vehicle from a depot means.
    if garageType ~= GarageType.DEPOT and playerVehicle.garage ~= garageName then
        exports.qbx_core:Notify(source, locale('error.not_here'), 'error')
        return
    end

    playerVehicle.props.lockState = 1 -- Modify the veh props lock state here to avoid conflicts with the vehicleConfig.noLock system.

    local warpPed = Config.warpInVehicle and GetPlayerPed(source)
    local netId, veh = qbx.spawnVehicle({ spawnSource = spawnCoords, model = playerVehicle.props.model, props = playerVehicle.props, warp = warpPed})

    if Config.doorsLocked then
        if GetResourceState('qbx_vehiclekeys') == 'started' then
            TriggerEvent('qb-vehiclekeys:server:setVehLockState', netId, 2)
        else
            SetVehicleDoorsLocked(veh, 2)
        end
    end

    TriggerClientEvent('vehiclekeys:client:SetOwner', source, playerVehicle.props.plate)

    Entity(veh).state:set('vehicleid', vehicleId, false)
    setVehicleStateToOut(vehicleId, veh, playerVehicle.modelName)
    TriggerEvent('qbx_garages:server:vehicleSpawned', veh)
    return netId
end)

function OverrideFreeDepotPriceForOutVehicle(vehicle)
    if VehicleState.OUT ~= vehicle.state then return end
    if vehicle.depotPrice and vehicle.depotPrice > 0 then return end

    vehicle.depotPrice = Config.calculateImpoundFee(vehicle.id, vehicle.modelName)
end
