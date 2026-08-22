local config = require 'config.shared'

-- Deliberately not restricted to job.type == 'business' - jim-mechanic's
-- shops use job.type == 'mechanic', and any other on-duty job resource
-- planting a reader should be able to use it too.
local function isOnDutyBusiness()
    return QBX.PlayerData.job.onduty
end

---Closest other player to `coords`, within `config.targetDistance`.
---@param coords vector3
---@return number? serverId
local function getNearestCustomer(coords)
    local players = GetActivePlayers()
    local closestId, closestDist = nil, config.targetDistance

    for i = 1, #players do
        local ped = GetPlayerPed(players[i])
        -- Self is included (not excluded) so a solo dev can charge their own
        -- ped to test the flow without needing a second player online.
        local dist = #(coords - GetEntityCoords(ped))

        if dist <= closestDist then
            closestId = GetPlayerServerId(players[i])
            closestDist = dist
        end
    end

    return closestId
end

local function sendInvoice(targetId, description, amount)
    TriggerServerEvent('crazy-invoicing:server:createInvoice', targetId, description, amount)
end

---Free-form fallback for businesses that didn't register a menu.
local function openInvoiceDialog(targetId)
    local input = lib.inputDialog(locale('input.title'), {
        {
            type = 'input',
            label = locale('input.description_label'),
            placeholder = locale('input.description_placeholder'),
            required = true,
        },
        {
            type = 'number',
            label = locale('input.amount_label'),
            min = 1,
            max = config.maxAmount,
            required = true,
        },
    })

    if not input then return end

    sendInvoice(targetId, input[1], input[2])
end

---Lets the employee pick one of the business's own priced items instead of
---typing a description/amount by hand.
---@param targetId number
---@param menu { name: string, label: string, price: number }[]
local function openMenuPicker(targetId, menu)
    local options = {}

    for i = 1, #menu do
        local item = menu[i]

        options[#options + 1] = {
            title = item.label,
            description = ('$%s'):format(item.price),
            icon = 'fa-solid fa-tag',
            onSelect = function()
                local qty = lib.inputDialog(item.label, {
                    { type = 'number', label = locale('input.quantity_label'), default = 1, min = 1, max = 50, required = true },
                })

                if not qty then return end

                qty = qty[1]
                local description = qty > 1 and ('%sx %s'):format(qty, item.label) or item.label

                sendInvoice(targetId, description, item.price * qty)
            end,
        }
    end

    options[#options + 1] = {
        title = locale('menu.custom_title'),
        description = locale('menu.custom_description'),
        icon = 'fa-solid fa-pen',
        onSelect = function() openInvoiceDialog(targetId) end,
    }

    lib.registerContext({
        id = 'crazy-invoicing:menu',
        title = locale('menu.title'),
        options = options,
    })

    lib.showContext('crazy-invoicing:menu')
end

---Finds whoever's standing closest to `coords` and opens the menu picker (if
---a menu was given) or the free-form dialog to bill them. Shared by the
---physical reader below and by AddCardReaderZone(...)/other resources hooking
---into an existing till of their own instead of spawning a new prop.
---@param coords vector3
---@param menu? { name: string, label: string, price: number }[]
local function chargeNearestCustomer(coords, menu)
    if not isOnDutyBusiness() then
        exports.qbx_core:Notify(locale('notify.not_on_duty'), 'error')
        return
    end

    local targetId = getNearestCustomer(coords)

    if not targetId then
        exports.qbx_core:Notify(locale('notify.no_customer'), 'error')
        return
    end

    if menu and #menu > 0 then
        openMenuPicker(targetId, menu)
    else
        openInvoiceDialog(targetId)
    end
end

exports('ChargeNearestCustomer', chargeNearestCustomer)

---Spawns a physical, interactable card reader prop - call once per business,
---client-side (each client spawns their own local copy at the same fixed
---coords, so it doesn't need network sync).
---@param coords vector3 | vector4
---@param heading? number
---@param menu? { name: string, label: string, price: number }[] the business's sellable items - falls back to a free-form description/amount prompt if omitted
exports('AddCardReader', function(coords, heading, menu)
    local model = `prop_till_01`
    lib.requestModel(model)

    local reader = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(reader, heading or (coords.w or 0.0))
    FreezeEntityPosition(reader, true)
    SetEntityInvincible(reader, true)
    PlaceObjectOnGroundProperly(reader)
    SetModelAsNoLongerNeeded(model)

    local readerCoords = GetEntityCoords(reader)

    exports.ox_target:addLocalEntity(reader, {
        {
            name = 'crazy-invoicing:charge',
            label = locale('target.charge'),
            icon = 'fa-solid fa-credit-card',
            distance = 2.0,
            canInteract = function() return isOnDutyBusiness() end,
            onSelect = function() chargeNearestCustomer(readerCoords, menu) end,
        },
    })

    return reader
end)

---Same as AddCardReader, but for a till another resource already placed
---itself (e.g. jim-mechanic's own counter props) - adds the interaction
---without spawning a second, overlapping prop.
---@param coords vector3 | vector4
---@param heading? number
---@param menu? { name: string, label: string, price: number }[]
exports('AddCardReaderZone', function(coords, heading, menu)
    exports.ox_target:addBoxZone({
        coords = coords.xyz,
        size = vec3(1.0, 1.0, 1.5),
        rotation = heading or (coords.w or 0.0),
        options = {
            {
                name = 'crazy-invoicing:charge',
                label = locale('target.charge'),
                icon = 'fa-solid fa-credit-card',
                distance = 2.0,
                canInteract = function() return isOnDutyBusiness() end,
                onSelect = function() chargeNearestCustomer(coords.xyz, menu) end,
            },
        },
    })
end)

RegisterNetEvent('crazy-invoicing:client:showInvoice', function(invoice)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showInvoice', data = invoice })
end)

RegisterNetEvent('crazy-invoicing:client:closeInvoice', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeInvoice' })
end)

RegisterNUICallback('payInvoice', function(data, cb)
    TriggerServerEvent('crazy-invoicing:server:payInvoice', data.id, data.method)
    cb(1)
end)

RegisterNUICallback('closeInvoice', function(_, cb)
    SetNuiFocus(false, false)
    cb(1)
end)
