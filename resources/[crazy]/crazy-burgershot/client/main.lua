local config = require 'config.shared'

local function isEmployee()
    return QBX.PlayerData.job.name == config.job
end

local function isOnDuty()
    return isEmployee() and QBX.PlayerData.job.onduty
end

local function isBoss()
    return isEmployee() and QBX.PlayerData.job.isboss
end

-- Map blip - GTA's own Burger Shot sprite/name, always visible like any other
-- restaurant POI (not gated to employees).
CreateThread(function()
    AddTextEntry('crazy_burgershot_blip', 'Burger Shot')

    local blip = AddBlipForCoord(config.locations.duty.x, config.locations.duty.y, config.locations.duty.z)
    SetBlipSprite(blip, 106)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.85)
    SetBlipColour(blip, 47)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('crazy_burgershot_blip')
    EndTextCommandSetBlipName(blip)
end)

-- Physical card reader on the register counter, for billing an actual nearby
-- player a custom amount (separate from the abstract "sell a menu item"
-- register interaction further down, which is for NPC-style walk-up sales).
exports['crazy-invoicing']:AddCardReader(config.locations.register, nil, config.menu)

-- Duty toggle
exports.ox_target:addBoxZone({
    coords = config.locations.duty.xyz,
    size = vec3(1.5, 1.5, 2.0),
    rotation = config.locations.duty.w,
    debug = false,
    options = {
        {
            name = 'crazy-burgershot:clockin',
            label = locale('target.duty_on'),
            icon = 'fa-solid fa-right-to-bracket',
            distance = 2.0,
            canInteract = function() return isEmployee() and not QBX.PlayerData.job.onduty end,
            onSelect = function() TriggerServerEvent('QBCore:ToggleDuty') end,
        },
        {
            name = 'crazy-burgershot:clockout',
            label = locale('target.duty_off'),
            icon = 'fa-solid fa-right-from-bracket',
            distance = 2.0,
            canInteract = function() return isOnDuty() end,
            onSelect = function() TriggerServerEvent('QBCore:ToggleDuty') end,
        },
    },
})

-- Management (boss menu) - hire/fire/promote, handled entirely by qbx_management
exports.ox_target:addBoxZone({
    coords = config.locations.management.xyz,
    size = vec3(1.5, 1.5, 2.0),
    rotation = config.locations.management.w,
    debug = false,
    options = {
        {
            name = 'crazy-burgershot:management',
            label = locale('target.management'),
            icon = 'fa-solid fa-users-gear',
            distance = 2.0,
            canInteract = function() return isBoss() end,
            onSelect = function() exports.qbx_management:OpenBossMenu('job') end,
        },
    },
})

-- Stock: buy raw ingredients out of the business account
local function openStockMenu()
    local options = {}

    for i = 1, #config.stock do
        local stock = config.stock[i]

        options[#options + 1] = {
            title = stock.label,
            description = locale('menu.stock_description', stock.cost, stock.amount, stock.label),
            icon = 'fa-solid fa-box',
            onSelect = function()
                TriggerServerEvent('crazy-burgershot:server:buyStock', stock.name)
            end,
        }
    end

    lib.registerContext({
        id = 'crazy-burgershot:stock',
        title = locale('menu.stock_title'),
        options = options,
    })

    lib.showContext('crazy-burgershot:stock')
end

exports.ox_target:addBoxZone({
    coords = config.locations.stock.xyz,
    size = vec3(2.0, 2.0, 2.0),
    rotation = config.locations.stock.w,
    debug = false,
    options = {
        {
            name = 'crazy-burgershot:stock',
            label = locale('target.stock'),
            icon = 'fa-solid fa-boxes-stacked',
            distance = 2.0,
            canInteract = function() return isOnDuty() end,
            onSelect = openStockMenu,
        },
    },
})

-- Register: sell finished menu items for the business
local function openRegisterMenu()
    local options = {}

    for i = 1, #config.menu do
        local item = config.menu[i]

        options[#options + 1] = {
            title = item.label,
            description = locale('menu.register_description', item.label, item.price),
            icon = 'fa-solid fa-cash-register',
            onSelect = function()
                TriggerServerEvent('crazy-burgershot:server:sellItem', item.name)
            end,
        }
    end

    lib.registerContext({
        id = 'crazy-burgershot:register',
        title = locale('menu.register_title'),
        options = options,
    })

    lib.showContext('crazy-burgershot:register')
end

exports.ox_target:addBoxZone({
    coords = config.locations.register.xyz,
    size = vec3(1.5, 1.5, 2.0),
    rotation = config.locations.register.w,
    debug = false,
    options = {
        {
            name = 'crazy-burgershot:register',
            label = locale('target.register'),
            icon = 'fa-solid fa-cash-register',
            distance = 2.0,
            canInteract = function() return isOnDuty() end,
            onSelect = openRegisterMenu,
        },
    },
})

-- Helper for placing the zones above accurately - prints your current
-- coords/heading (as a ready-to-paste vec4) to the F8 console and a notify.
-- Harmless/read-only, so it's left unrestricted like a plain /coords command.
RegisterCommand('bslocation', function()
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local msg = ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, heading)

    print(('[crazy-burgershot] %s'):format(msg))
    lib.notify({ description = msg, duration = 8000 })
end, false)
