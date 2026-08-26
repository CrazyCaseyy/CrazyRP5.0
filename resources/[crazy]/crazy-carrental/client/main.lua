local function attemptRent(vehicleConfig, moneyType)
    local success = lib.callback.await('crazy-carrental:server:rentVehicle', false, vehicleConfig.model, moneyType)
    if not success then
        exports.qbx_core:Notify(('Could not rent the %s.'):format(vehicleConfig.label), 'error')
    end
end

local function openPaymentMenu(vehicleConfig)
    lib.registerContext({
        id = 'crazy_carrental_payment',
        title = ('Pay for %s ($%s)'):format(vehicleConfig.label, vehicleConfig.price),
        menu = 'crazy_carrental_vehicles',
        options = {
            {
                title = 'Cash',
                icon = 'money-bill-wave',
                onSelect = function() attemptRent(vehicleConfig, 'cash') end,
            },
            {
                title = 'Card',
                icon = 'credit-card',
                onSelect = function() attemptRent(vehicleConfig, 'bank') end,
            },
        },
    })
    lib.showContext('crazy_carrental_payment')
end

local function openVehicleMenu()
    local options = {}
    for i = 1, #Config.Vehicles do
        local vehicleConfig = Config.Vehicles[i]
        options[#options + 1] = {
            title = vehicleConfig.label,
            description = ('$%s'):format(vehicleConfig.price),
            icon = 'car',
            arrow = true,
            onSelect = function() openPaymentMenu(vehicleConfig) end,
        }
    end

    lib.registerContext({
        id = 'crazy_carrental_vehicles',
        title = 'Rent a Vehicle',
        options = options,
    })
    lib.showContext('crazy_carrental_vehicles')
end

local function returnVehicle()
    local success = lib.callback.await('crazy-carrental:server:returnVehicle', false)
    if not success then
        exports.qbx_core:Notify('Could not return that vehicle.', 'error')
    end
end

local function openReturnMenu(rental)
    lib.registerContext({
        id = 'crazy_carrental_return',
        title = 'Vehicle Rental',
        options = {
            {
                title = ('Return your %s'):format(rental.label),
                description = ('Refund: $%s'):format(rental.price),
                icon = 'right-left',
                onSelect = returnVehicle,
            },
        },
    })
    lib.showContext('crazy_carrental_return')
end

-- Only one rental out at a time per player, so the ped either offers the
-- rent menu or the return menu - never both.
local function onTalkToClerk()
    local rental = lib.callback.await('crazy-carrental:server:getActiveRental', false)
    if rental then
        openReturnMenu(rental)
    else
        openVehicleMenu()
    end
end

CreateThread(function()
    local model = joaat(Config.Ped.model)
    if not lib.requestModel(model, 5000) then
        print(('^1[crazy-carrental]^7 failed to load ped model %s - rental clerk was not spawned'):format(Config.Ped.model))
        return
    end

    local coords = Config.Ped.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 then
        print('^1[crazy-carrental]^7 CreatePed returned an invalid entity - rental clerk was not spawned')
        return
    end

    SetPedDefaultComponentVariation(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)

    exports.ox_target:addLocalEntity(ped, {{
        name = 'crazy_carrental_clerk',
        icon = 'fa-solid fa-car',
        label = 'Vehicle Rental',
        distance = 1.5,
        onSelect = onTalkToClerk,
    }})
end)
