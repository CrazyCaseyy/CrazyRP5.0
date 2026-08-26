-- One active rental per citizenid at a time. Keyed by citizenid (not
-- source) so it survives a disconnect/reconnect - the clerk will still
-- offer the return/refund option next time they talk to them.
---@type table<string, { vehicle: number, label: string, price: number, moneyType: 'cash' | 'bank' }>
local activeRentals = {}

local function getVehicleConfig(modelName)
    for i = 1, #Config.Vehicles do
        if Config.Vehicles[i].model == modelName then
            return Config.Vehicles[i]
        end
    end
end

---@param source number
---@param modelName string
---@param moneyType 'cash' | 'bank'
---@return boolean success
local function rentVehicle(source, modelName, moneyType)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    if activeRentals[player.PlayerData.citizenid] then
        exports.qbx_core:Notify(source, 'You already have a rental out. Return it first.', 'error')
        return false
    end

    local vehicleConfig = getVehicleConfig(modelName)
    if not vehicleConfig then return false end

    local removed = player.Functions.RemoveMoney(moneyType, vehicleConfig.price, ('Rented a %s'):format(vehicleConfig.label))
    if not removed then
        exports.qbx_core:Notify(source, 'Not enough money for that.', 'error')
        return false
    end

    local netId, veh = qbx.spawnVehicle({
        model = joaat(modelName),
        spawnSource = Config.SpawnPoint,
        warp = GetPlayerPed(source),
    })

    if not netId or netId == 0 or not veh or veh == 0 then
        player.Functions.AddMoney(moneyType, vehicleConfig.price, 'Rental refund - vehicle failed to spawn')
        exports.qbx_core:Notify(source, 'Something went wrong spawning that vehicle.', 'error')
        return false
    end

    exports.qbx_vehiclekeys:GiveKeys(source, veh)

    activeRentals[player.PlayerData.citizenid] = {
        vehicle = veh,
        label = vehicleConfig.label,
        price = vehicleConfig.price,
        moneyType = moneyType,
    }

    -- crazy-tutorial listens for this to mark its "Rent a car" step done.
    TriggerEvent('crazy-carrental:server:vehicleRented', source, modelName)

    return true
end

---@param source number
---@return boolean success
local function returnVehicle(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    local rental = activeRentals[player.PlayerData.citizenid]
    if not rental then return false end

    if DoesEntityExist(rental.vehicle) then
        DeleteEntity(rental.vehicle)
    end

    activeRentals[player.PlayerData.citizenid] = nil
    player.Functions.AddMoney(rental.moneyType, rental.price, ('Refund - returned %s'):format(rental.label))
    exports.qbx_core:Notify(source, ('Refunded $%s.'):format(rental.price), 'success')

    return true
end

lib.callback.register('crazy-carrental:server:rentVehicle', function(source, modelName, moneyType)
    return rentVehicle(source, modelName, moneyType)
end)

lib.callback.register('crazy-carrental:server:returnVehicle', function(source)
    return returnVehicle(source)
end)

---@return { label: string, price: number } | nil
lib.callback.register('crazy-carrental:server:getActiveRental', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local rental = activeRentals[player.PlayerData.citizenid]
    if not rental then return nil end

    return { label = rental.label, price = rental.price }
end)
