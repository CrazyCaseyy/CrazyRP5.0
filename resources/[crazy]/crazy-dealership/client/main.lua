local function purchaseVehicle(vehicle)
    local alert = lib.alertDialog({
        header = ('Purchase %s'):format(vehicle.name),
        content = ('Buy the %s for $%s? This will come out of your bank account.'):format(vehicle.name, lib.math.groupdigits(vehicle.price)),
        centered = true,
        cancel = true,
    })
    if alert ~= 'confirm' then return end

    local result = lib.callback.await('crazy-dealership:server:purchaseVehicle', false, vehicle.model)
    exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
end

local function startTestDrive(vehicle)
    local netId = lib.callback.await('crazy-dealership:server:startTestDrive', false, vehicle.model)
    if not netId then
        return exports.qbx_core:Notify('Could not start the test drive.', 'error')
    end

    -- Standard ox_lib timed-activity bar - depletes over the test drive
    -- duration. Movement/driving stay enabled so they can actually drive
    -- it; only combat is disabled.
    lib.progressBar({
        duration = Config.TestDriveDuration * 1000,
        label = ('Test Driving the %s'):format(vehicle.name),
        canCancel = false,
        disable = { move = false, car = false, combat = true, mouse = false, sprint = false },
    })

    TriggerServerEvent('crazy-dealership:server:endTestDrive', netId)
    exports.qbx_core:Notify('Your test drive has ended.', 'inform')
end

local function openVehicleMenu(vehicle)
    lib.registerContext({
        id = 'crazy_dealership_vehicle',
        title = vehicle.name,
        menu = 'crazy_dealership_category_' .. vehicle.category,
        options = {
            {
                title = 'Purchase',
                description = ('$%s'):format(lib.math.groupdigits(vehicle.price)),
                icon = 'dollar-sign',
                onSelect = function() purchaseVehicle(vehicle) end,
            },
            {
                title = 'Test Drive',
                description = ('%s seconds'):format(Config.TestDriveDuration),
                icon = 'car-side',
                onSelect = function() startTestDrive(vehicle) end,
            },
        },
    })
    lib.showContext('crazy_dealership_vehicle')
end

local function openCategoryMenu(categoryKey, label, vehicles)
    local options = {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        options[#options + 1] = {
            title = vehicle.name,
            description = ('%s - $%s'):format(vehicle.brand, lib.math.groupdigits(vehicle.price)),
            icon = 'car',
            arrow = true,
            onSelect = function() openVehicleMenu(vehicle) end,
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
        id = 'crazy_dealership_category_' .. categoryKey,
        title = label,
        menu = 'crazy_dealership_categories',
        options = options,
    })
    lib.showContext('crazy_dealership_category_' .. categoryKey)
end

local function openDealership()
    local catalog = lib.callback.await('crazy-dealership:server:getCatalog', false)
    if not catalog then
        return exports.qbx_core:Notify('Could not load the catalog.', 'error')
    end

    local options = {}
    for _, cat in ipairs(Config.Categories) do
        options[#options + 1] = {
            title = cat.label,
            icon = 'car',
            arrow = true,
            onSelect = function() openCategoryMenu(cat.key, cat.label, catalog[cat.key] or {}) end,
        }
    end

    options[#options + 1] = {
        title = 'Custom Cars',
        icon = 'star',
        arrow = true,
        onSelect = function() openCategoryMenu('custom', 'Custom Cars', catalog.custom or {}) end,
    }

    lib.registerContext({
        id = 'crazy_dealership_categories',
        title = 'Dealership',
        options = options,
    })
    lib.showContext('crazy_dealership_categories')
end

exports.ox_target:addSphereZone({
    coords = Config.Location,
    radius = Config.TargetRadius,
    options = {
        {
            name = 'crazy_dealership_open',
            icon = 'fa-solid fa-car',
            label = 'Browse Vehicles',
            onSelect = openDealership,
        },
    },
    debug = false,
})
