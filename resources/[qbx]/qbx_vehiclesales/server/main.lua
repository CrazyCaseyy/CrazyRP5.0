local config = require 'config.client'

local catalog
local catalogByModel
local activeTestDrives = {} -- [source] = netId, so endTestDrive can only ever delete the vehicle that player's own test drive actually spawned

-- [previewIndex] = model. Defaults every spot to a Sultan on every
-- restart rather than starting empty, so the lot never looks bare until
-- someone happens to change a display car.
local previewState = {}
for i = 1, #config.previewPoints do
    previewState[i] = 'sultan'
end

---@return table<string, { model: string, name: string, brand: string, price: number, category: string }[]>
local function buildCatalog()
    local vehicles = exports.qbx_core:GetVehiclesByName()

    local allowedCategories = {}
    for _, cat in ipairs(config.categories) do allowedCategories[cat.key] = true end

    local excluded = {}
    for _, model in ipairs(config.excludedModels) do excluded[model] = true end

    local grouped = {}
    for _, cat in ipairs(config.categories) do grouped[cat.key] = {} end

    catalogByModel = {}

    for model, veh in pairs(vehicles) do
        if allowedCategories[veh.category] and not excluded[model] then
            local entry = { model = model, name = veh.name, brand = veh.brand, price = veh.price, category = veh.category }
            table.insert(grouped[veh.category], entry)
            catalogByModel[model] = entry
        end
    end

    grouped.custom = {}
    for _, veh in ipairs(config.customVehicles) do
        local entry = { model = veh.model, name = veh.name, brand = veh.brand, price = veh.price, category = 'custom' }
        table.insert(grouped.custom, entry)
        catalogByModel[veh.model] = entry
    end

    for _, list in pairs(grouped) do
        table.sort(list, function(a, b) return a.name < b.name end)
    end

    return grouped
end

lib.callback.register('qbx_vehiclesales:server:getCatalog', function(source)
    if not catalog then catalog = buildCatalog() end
    return catalog
end)

-- Manager/boss grades of the pdm job only - the catalog itself stays
-- editable in place (catalogByModel entries are shared with catalog, so
-- this is visible to every player's next getCatalog fetch, no rebuild
-- needed).
lib.callback.register('qbx_vehiclesales:server:setPrice', function(source, model, newPrice)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'pdm' or player.PlayerData.job.grade.level < 2 then
        return { success = false, message = 'You are not authorized to do that.' }
    end

    newPrice = tonumber(newPrice)
    if not newPrice or newPrice < 0 then
        return { success = false, message = 'Enter a valid price.' }
    end

    if not catalog then catalog = buildCatalog() end
    local entry = catalogByModel[model]
    if not entry then return { success = false, message = 'That vehicle is not for sale here.' } end

    entry.price = math.floor(newPrice)
    return { success = true, message = ('Updated the %s to $%s.'):format(entry.name, lib.math.groupdigits(entry.price)) }
end)

lib.callback.register('qbx_vehiclesales:server:purchaseVehicle', function(source, model)
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

lib.callback.register('qbx_vehiclesales:server:startTestDrive', function(source, model)
    if not catalogByModel or not catalogByModel[model] then return end

    local netId, veh = qbx.spawnVehicle({
        model = joaat(model),
        spawnSource = config.testDriveSpawn,
        warp = GetPlayerPed(source),
    })

    if not netId or netId == 0 or not veh or veh == 0 then return end

    exports.qbx_vehiclekeys:GiveKeys(source, veh)
    activeTestDrives[source] = netId

    return netId
end)

RegisterNetEvent('qbx_vehiclesales:server:endTestDrive', function(netId)
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

lib.callback.register('qbx_vehiclesales:server:getPreviews', function(source)
    return previewState
end)

RegisterNetEvent('qbx_vehiclesales:server:setPreview', function(previewIndex, model)
    if type(previewIndex) ~= 'number' or previewIndex < 1 or previewIndex > #config.previewPoints then return end
    if not catalog then catalog = buildCatalog() end
    if not catalogByModel[model] then return end

    previewState[previewIndex] = model
    TriggerClientEvent('qbx_vehiclesales:client:updatePreview', -1, previewIndex, model)
end)
