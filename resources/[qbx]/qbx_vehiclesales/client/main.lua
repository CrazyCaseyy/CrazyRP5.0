local config = require 'config.client'

-- Each browsePoint is paired with whichever previewPoint is physically
-- closest to it, computed once at load rather than hardcoded, so this
-- still works correctly if points are ever added/moved. previewIndexFor
-- looks up that pairing by browse point index.
local previewIndexFor = {}
for browseI, browseCoords in ipairs(config.browsePoints) do
    local closest, closestDist
    for previewI, previewCoords in ipairs(config.previewPoints) do
        local dist = #(browseCoords - previewCoords.xyz)
        if not closestDist or dist < closestDist then
            closest, closestDist = previewI, dist
        end
    end
    previewIndexFor[browseI] = closest
end

local previewVehicles = {} -- [previewIndex] = entity
local currentPreviewModel = {} -- [previewIndex] = model, so menus can tell what's already on display

local function updatePreview(previewIndex, model)
    local existing = previewVehicles[previewIndex]
    if existing and DoesEntityExist(existing) then
        DeleteEntity(existing)
    end
    previewVehicles[previewIndex] = nil
    currentPreviewModel[previewIndex] = model

    if not model then return end

    local coords = config.previewPoints[previewIndex]
    if not coords then return end

    local hash = joaat(model)
    lib.requestModel(hash, 5000)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(hash)

    SetEntityInvincible(veh, true)
    FreezeEntityPosition(veh, true)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleUndriveable(veh, true)

    previewVehicles[previewIndex] = veh
end

RegisterNetEvent('qbx_vehiclesales:client:updatePreview', function(previewIndex, model)
    updatePreview(previewIndex, model)
end)

local function setPreview(browseIndex, vehicle)
    local previewIndex = previewIndexFor[browseIndex]
    if not previewIndex then return end

    TriggerServerEvent('qbx_vehiclesales:server:setPreview', previewIndex, vehicle.model)
    exports.qbx_core:Notify(('Now previewing the %s.'):format(vehicle.name), 'success')
end

local function purchaseVehicle(vehicle)
    local alert = lib.alertDialog({
        header = ('Purchase %s'):format(vehicle.name),
        content = ('Buy the %s for $%s? This will come out of your bank account.'):format(vehicle.name, lib.math.groupdigits(vehicle.price)),
        centered = true,
        cancel = true,
    })
    if alert ~= 'confirm' then return end

    local result = lib.callback.await('qbx_vehiclesales:server:purchaseVehicle', false, vehicle.model)
    exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
end

-- No progress bar (it has its own busy-state that can get in the way of
-- ox_target elsewhere) and no ox_target zone for the return either -
-- both live as plain lib.showTextUI prompts instead, matching the style
-- crazy-hud's own "Start Engine" prompt uses (a badge/label pill, not a
-- depleting bar): a left-side countdown while driving around, which
-- swaps to a bottom-center "[E] - Return Test Drive" prompt (crazy-hud's
-- Start Engine prompt's own position) the moment they're back at the
-- spawn point, ending the test drive on that keypress.
local function startTestDrive(vehicle)
    local netId = lib.callback.await('qbx_vehiclesales:server:startTestDrive', false, vehicle.model)
    if not netId then
        return exports.qbx_core:Notify('Could not start the test drive.', 'error')
    end

    local startTime = GetGameTimer()
    local durationMs = config.testDriveDuration * 1000
    local spawnCoords = config.testDriveSpawn.xyz

    CreateThread(function()
        while true do
            Wait(0)

            local remaining = durationMs - (GetGameTimer() - startTime)
            if remaining <= 0 then break end

            if #(GetEntityCoords(cache.ped) - spawnCoords) < config.targetRadius then
                lib.showTextUI('[E] - Return Test Drive', { position = 'bottom-center' })
                if IsControlJustPressed(0, 38) then break end
            else
                lib.showTextUI(('Test Drive: %ds remaining'):format(math.ceil(remaining / 1000)), { position = 'left-center' })
            end
        end

        lib.hideTextUI()
        TriggerServerEvent('qbx_vehiclesales:server:endTestDrive', netId)
        exports.qbx_core:Notify('Your test drive has ended.', 'inform')
    end)
end

local openVehicleMenu

local function editPrice(vehicle, browseIndex, backMenu)
    local data = lib.inputDialog(('Edit Price - %s'):format(vehicle.name), {
        { type = 'number', label = 'Price', description = 'New purchase price for this vehicle', default = vehicle.price, min = 0, required = true },
    })
    if not data then return end

    local result = lib.callback.await('qbx_vehiclesales:server:setPrice', false, vehicle.model, data[1])
    exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
    if result.success then
        vehicle.price = data[1]
        openVehicleMenu(vehicle, browseIndex, backMenu)
    end
end

openVehicleMenu = function(vehicle, browseIndex, backMenu)
    local options = {
        {
            title = 'Purchase',
            description = ('$%s'):format(lib.math.groupdigits(vehicle.price)),
            icon = 'dollar-sign',
            onSelect = function() purchaseVehicle(vehicle) end,
        },
        {
            title = 'Test Drive',
            description = ('%s seconds'):format(config.testDriveDuration),
            icon = 'car-side',
            onSelect = function() startTestDrive(vehicle) end,
        },
    }

    -- Manager/boss grades of the pdm job only.
    if QBX.PlayerData.job.name == 'pdm' and QBX.PlayerData.job.grade.level >= 2 then
        options[#options + 1] = {
            title = 'Edit Price',
            description = 'Change what this vehicle sells for',
            icon = 'pen-to-square',
            onSelect = function() editPrice(vehicle, browseIndex, backMenu) end,
        }
    end

    -- Already the car on display at the spot nearest this menu - no point
    -- offering to display it again.
    local previewIndex = previewIndexFor[browseIndex]
    if not previewIndex or currentPreviewModel[previewIndex] ~= vehicle.model then
        options[#options + 1] = {
            title = 'Set as Preview',
            description = 'Show this car on the display spot nearest you',
            icon = 'eye',
            onSelect = function() setPreview(browseIndex, vehicle) end,
        }
    end

    lib.registerContext({
        id = 'qbx_vehiclesales_vehicle',
        title = vehicle.name,
        menu = backMenu or ('qbx_vehiclesales_category_' .. vehicle.category),
        options = options,
    })
    lib.showContext('qbx_vehiclesales_vehicle')
end

local function openCategoryMenu(categoryKey, label, vehicles, browseIndex)
    local options = {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        options[#options + 1] = {
            title = vehicle.name,
            description = ('%s - $%s'):format(vehicle.brand, lib.math.groupdigits(vehicle.price)),
            icon = 'car',
            arrow = true,
            onSelect = function() openVehicleMenu(vehicle, browseIndex) end,
        }
    end

    if #options == 0 then
        options[1] = {
            title = 'Nothing here yet',
            description = 'Check back later',
            icon = 'circle-info',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'qbx_vehiclesales_category_' .. categoryKey,
        title = label,
        menu = 'qbx_vehiclesales_categories',
        options = options,
    })
    lib.showContext('qbx_vehiclesales_category_' .. categoryKey)
end

---@return table? vehicle the catalog entry for this model, searching every category including custom
local function findInCatalog(catalog, model)
    for _, list in pairs(catalog) do
        for i = 1, #list do
            if list[i].model == model then return list[i] end
        end
    end
end

local function openDealership(browseIndex)
    local catalog = lib.callback.await('qbx_vehiclesales:server:getCatalog', false)
    if not catalog then
        return exports.qbx_core:Notify('Could not load the catalog.', 'error')
    end

    local options = {}

    -- Whatever's already on display at the spot nearest this menu, right
    -- at the top so it's one click to buy or test drive it.
    local previewIndex = previewIndexFor[browseIndex]
    local displayedModel = previewIndex and currentPreviewModel[previewIndex]
    local displayedVehicle = displayedModel and findInCatalog(catalog, displayedModel)
    if displayedVehicle then
        options[#options + 1] = {
            title = displayedVehicle.name,
            description = ('On display now - %s - $%s'):format(displayedVehicle.brand, lib.math.groupdigits(displayedVehicle.price)),
            icon = 'eye',
            arrow = true,
            onSelect = function() openVehicleMenu(displayedVehicle, browseIndex, 'qbx_vehiclesales_categories') end,
        }
    end

    for _, cat in ipairs(config.categories) do
        options[#options + 1] = {
            title = cat.label,
            icon = 'car',
            arrow = true,
            onSelect = function() openCategoryMenu(cat.key, cat.label, catalog[cat.key] or {}, browseIndex) end,
        }
    end

    options[#options + 1] = {
        title = 'Custom Cars',
        icon = 'star',
        arrow = true,
        onSelect = function() openCategoryMenu('custom', 'Custom Cars', catalog.custom or {}, browseIndex) end,
    }

    lib.registerContext({
        id = 'qbx_vehiclesales_categories',
        title = 'Dealership',
        options = options,
    })
    lib.showContext('qbx_vehiclesales_categories')
end

-- The game itself (not any of our scripts) bakes in permanent vehicle-dealer
-- map blips (sprite 326, the same icon vanilla PDM and this resource's own
-- blip below both use) - removing the shop from qbx_vehicleshop's config
-- doesn't touch these, they're part of the game's own default blip list, not
-- resource-added. Matched by sprite rather than a guessed coordinate so it
-- reliably strips every stock dealer icon; ourBlip is passed in and skipped
-- so this can never eat our own blip on a later sweep.
local function removeStockDealerBlips(ourBlip)
    for category = 0, 10 do
        local blip = GetFirstBlipInfoId(category)
        while DoesBlipExist(blip) do
            local nextBlip = GetNextBlipInfoId(category)
            if blip ~= ourBlip and GetBlipSprite(blip) == 326 then
                RemoveBlip(blip)
            end
            blip = nextBlip
        end
    end
end

CreateThread(function()
    local blipCoords = config.browsePoints[1]
    local blip = AddBlipForCoord(blipCoords.x, blipCoords.y, blipCoords.z)
    SetBlipSprite(blip, 326)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Premium Deluxe Motorsport')
    EndTextCommandSetBlipName(blip)

    -- The game adds its default blips asynchronously as the world streams
    -- in, sometimes after this resource has already started - sweep a few
    -- times over the first several seconds rather than trusting a single
    -- pass at t=0.
    removeStockDealerBlips(blip)
    for _ = 1, 5 do
        Wait(1000)
        removeStockDealerBlips(blip)
    end

    for i, coords in ipairs(config.browsePoints) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = config.targetRadius,
            options = {
                {
                    name = 'qbx_vehiclesales_open_' .. i,
                    icon = 'fa-solid fa-car',
                    label = 'Browse Vehicles',
                    onSelect = function() openDealership(i) end,
                },
            },
            debug = false,
        })
    end

    -- Sync whatever's already being previewed (set by other players, or
    -- from before this client loaded in) rather than starting blank.
    local previews = lib.callback.await('qbx_vehiclesales:server:getPreviews', false)
    if previews then
        for previewIndex, model in pairs(previews) do
            updatePreview(previewIndex, model)
        end
    end
end)
