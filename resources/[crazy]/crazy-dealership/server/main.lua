local catalog
local catalogByModel
local activeTestDrives = {} -- [source] = netId, so endTestDrive can only ever delete the vehicle that player's own test drive actually spawned

---@return table<string, { model: string, name: string, brand: string, price: number, category: string }[]>
local function buildCatalog()
    local vehicles = exports.qbx_core:GetVehiclesByName()

    local allowedCategories = {}
    for _, cat in ipairs(Config.Categories) do allowedCategories[cat.key] = true end

    local excluded = {}
    for _, model in ipairs(Config.ExcludedModels) do excluded[model] = true end

    local grouped = {}
    for _, cat in ipairs(Config.Categories) do grouped[cat.key] = {} end

    catalogByModel = {}

    for model, veh in pairs(vehicles) do
        if allowedCategories[veh.category] and not excluded[model] then
            local entry = { model = model, name = veh.name, brand = veh.brand, price = veh.price, category = veh.category }
            table.insert(grouped[veh.category], entry)
            catalogByModel[model] = entry
        end
    end

    grouped.custom = {}
    for _, veh in ipairs(Config.CustomVehicles) do
        local entry = { model = veh.model, name = veh.name, brand = veh.brand, price = veh.price, category = 'custom' }
        table.insert(grouped.custom, entry)
        catalogByModel[veh.model] = entry
    end

    for _, list in pairs(grouped) do
        table.sort(list, function(a, b) return a.name < b.name end)
    end

    return grouped
end

lib.callback.register('crazy-dealership:server:getCatalog', function(source)
    if not catalog then catalog = buildCatalog() end
    return catalog
end)

lib.callback.register('crazy-dealership:server:purchaseVehicle', function(source, model)
    if not catalogByModel or not catalogByModel[model] then return { success = false, message = 'That vehicle is not for sale here.' } end

    local vehicle = catalogByModel[model]
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { success = false, message = 'Something went wrong.' } end

    local removed = player.Functions.RemoveMoney('bank', vehicle.price, ('Purchased a %s'):format(vehicle.name))
    if not removed then
        return { success = false, message = 'Not enough money in your bank account.' }
    end

    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
        model = model,
        citizenid = player.PlayerData.citizenid,
    })

    if not vehicleId then
        player.Functions.AddMoney('bank', vehicle.price, 'Purchase refund - failed to register vehicle')
        return { success = false, message = 'Something went wrong registering that vehicle.' }
    end

    return { success = true, message = ('Purchased the %s - check your garage.'):format(vehicle.name) }
end)

lib.callback.register('crazy-dealership:server:startTestDrive', function(source, model)
    if not catalogByModel or not catalogByModel[model] then return end

    local netId, veh = qbx.spawnVehicle({
        model = joaat(model),
        spawnSource = Config.TestDriveSpawn,
        warp = GetPlayerPed(source),
    })

    if not netId or netId == 0 or not veh or veh == 0 then return end

    exports.qbx_vehiclekeys:GiveKeys(source, veh)
    activeTestDrives[source] = netId

    return netId
end)

RegisterNetEvent('crazy-dealership:server:endTestDrive', function(netId)
    local source = source
    -- Only ever the vehicle that player's own test drive actually spawned -
    -- not an arbitrary netId, so this can't be used to delete anyone else's.
    if activeTestDrives[source] ~= netId then return end
    activeTestDrives[source] = nil

    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
end)

AddEventHandler('playerDropped', function()
    activeTestDrives[source] = nil
end)
