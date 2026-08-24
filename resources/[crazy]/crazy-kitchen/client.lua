--[[ ══════════════════════════════════════════════════════════════
     Crazy Kitchen Stations – Client
     ══════════════════════════════════════════════════════════════ ]]
local activeStation = nil
local uiOpen        = false
local uiMode        = nil   -- 'craft' | 'supply'
local craftRAF      = nil   -- used only to cancel animation if needed

-- Forward declarations
local openSupplierMenu

-- ─────────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────────

local function notify(msg, ntype)
    lib.notify({ title = 'Business Station', description = msg, type = ntype or 'inform' })
end

local function hasJob(jobName)
    local job = QBX.PlayerData.job
    return job and job.name == jobName
end

local function isOnDuty()
    return QBX.PlayerData.job.onduty
end

local function closeUI()
    if not uiOpen then return end
    if activeStation and uiMode == 'craft' then
        TriggerServerEvent('crazy-kitchen:unregisterViewer', activeStation.id)
    end
    uiOpen        = false
    uiMode        = nil
    activeStation = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Build recipe payload with resolved item labels from ox_inventory
local function buildRecipePayload(station)
    local recipes = {}
    for _, r in ipairs(station.recipes) do
        local ingredients = {}
        for _, ing in ipairs(r.ingredients) do
            local itemData = exports.ox_inventory:Items(ing.item)
            ingredients[#ingredients + 1] = {
                item = ing.item,
                name = itemData and itemData.label or ing.item,
                qty  = ing.qty,
            }
        end
        recipes[#recipes + 1] = {
            id          = r.id,
            name        = r.name,
            icon        = r.icon,
            craftTime   = r.craftTime,
            yield       = r.yield,
            output      = r.output,
            ingredients = ingredients,
        }
    end
    return recipes
end

-- ─────────────────────────────────────────────────────────────────
--  Register ox_target zones for every station on resource start
-- ─────────────────────────────────────────────────────────────────

CreateThread(function()
    for _, station in ipairs(Config.Stations) do
        local sid = station.id
        local job = station.job

        exports.ox_target:addSphereZone({
            coords  = station.coords,
            radius  = Config.InteractionDistance,
            debug   = false,
            options = {
                {
                    name     = 'kitchen_open_' .. sid,
                    icon     = Config.TargetIcon,
                    label    = 'Use Business Station',
                    -- job lock + duty check: only show if player has the right job and is on duty
                    canInteract = function()
                        return hasJob(job) and isOnDuty()
                    end,
                    onSelect = function()
                        TriggerEvent('crazy-kitchen:openStation', sid)
                    end,
                },
                {
                    name     = 'kitchen_storage_' .. sid,
                    icon     = Config.StorageIcon,
                    label    = 'Open Business Storage',
                    canInteract = function()
                        return hasJob(job) and isOnDuty()
                    end,
                    onSelect = function()
                        TriggerEvent('crazy-kitchen:openStorage', sid)
                    end,
                },
            },
        })

        -- Dedicated supplier zone — separate from the station itself
        if station.supplier and station.supplies and #station.supplies > 0 then
            exports.ox_target:addBoxZone({
                coords   = vector3(station.supplier.coords.x, station.supplier.coords.y, station.supplier.coords.z),
                size     = vector3(1.0, 1.0, 2.0),
                rotation = station.supplier.coords.w,
                debug    = false,
                options  = {
                    {
                        name     = 'kitchen_supplier_' .. sid,
                        icon     = Config.SupplierIcon,
                        label    = 'Order Supplies',
                        canInteract = function()
                            return hasJob(job) and isOnDuty()
                        end,
                        onSelect = function()
                            openSupplierMenu(station)
                        end,
                    },
                },
            })
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
--  Open Kitchen UI
-- ─────────────────────────────────────────────────────────────────

RegisterNetEvent('crazy-kitchen:openStation', function(stationId)
    if uiOpen then return end

    local station
    for _, s in ipairs(Config.Stations) do
        if s.id == stationId then station = s break end
    end
    if not station then return end

    -- Double-check job and duty status on client before opening
    if not hasJob(station.job) then
        notify('You are not employed here.', 'error')
        return
    end
    if not isOnDuty() then
        notify('You must be on duty to use the business station.', 'error')
        return
    end

    activeStation = station
    uiOpen        = true
    uiMode        = 'craft'

    local currentQueue = lib.callback.await('crazy-kitchen:getQueue', false, station.id)
    TriggerServerEvent('crazy-kitchen:registerViewer', station.id)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'open',
        business = station.label,
        stashId  = 'craft_' .. station.id,
        recipes  = buildRecipePayload(station),
        queue    = currentQueue or {},
    })
end)

-- ─────────────────────────────────────────────────────────────────
--  Open Kitchen Storage
-- ─────────────────────────────────────────────────────────────────

RegisterNetEvent('crazy-kitchen:openStorage', function(stationId)
    local station
    for _, s in ipairs(Config.Stations) do
        if s.id == stationId then station = s break end
    end
    if not station then return end

    if not hasJob(station.job) then
        notify('You are not employed here.', 'error')
        return
    end
    if not isOnDuty() then
        notify('You must be on duty to access business storage.', 'error')
        return
    end

    TriggerServerEvent('crazy-kitchen:openStash', station.id)
end)

RegisterNetEvent('crazy-kitchen:openStashClient', function(stashId)
    exports.ox_inventory:openInventory('stash', stashId)
end)

-- ─────────────────────────────────────────────────────────────────
--  Order Supplies — buy raw ingredients into the business stash
-- ─────────────────────────────────────────────────────────────────

-- Build supply payload with resolved item labels from ox_inventory
local function buildSupplyPayload(station)
    local supplies = {}
    for _, entry in ipairs(station.supplies) do
        local itemData = exports.ox_inventory:Items(entry.item)
        supplies[#supplies + 1] = {
            item  = entry.item,
            name  = itemData and itemData.label or entry.item,
            price = entry.price,
        }
    end
    return supplies
end

openSupplierMenu = function(station)
    if uiOpen then return end
    if not hasJob(station.job) then
        notify('You are not employed here.', 'error')
        return
    end
    if not isOnDuty() then
        notify('You must be on duty to order supplies.', 'error')
        return
    end

    activeStation = station
    uiOpen        = true
    uiMode        = 'supply'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'openSupplier',
        business = station.label,
        supplies = buildSupplyPayload(station),
    })
end

RegisterNetEvent('crazy-kitchen:buySupplyResponse', function(response)
    SendNUIMessage({ action = 'buySupplyResponse', data = response })
    if response.ok then
        notify(('Purchased %dx %s for $%d.'):format(response.qty, response.label, response.total), 'success')
    else
        notify(response.reason or 'Purchase failed.', 'error')
    end
end)

-- ─────────────────────────────────────────────────────────────────
--  NUI Callbacks
-- ─────────────────────────────────────────────────────────────────

-- Player pressed Queue on a recipe
RegisterNUICallback('addToQueue', function(data, cb)
    if not activeStation then cb({ ok = false, reason = 'No active station.' }) return end

    TriggerServerEvent('crazy-kitchen:addToQueue', {
        stationId = activeStation.id,
        recipeId  = data.recipeId,
        qty       = data.qty,
        stashId   = 'craft_' .. activeStation.id,
    })

    cb({ ok = true })
end)

-- Player pressed Cancel on a queued item
RegisterNUICallback('cancelQueue', function(data, cb)
    -- data: { queueId }
    TriggerServerEvent('crazy-kitchen:cancelQueue', {
        stationId = activeStation and activeStation.id or nil,
        queueId   = data.queueId,
    })
    cb({ ok = true })
end)

-- Player pressed Buy on a supply card
RegisterNUICallback('buySupply', function(data, cb)
    if not activeStation then cb({ ok = false, reason = 'No active station.' }) return end

    TriggerServerEvent('crazy-kitchen:buySupply', {
        stationId = activeStation.id,
        item      = data.item,
        qty       = data.qty,
        method    = 'cash',
    })

    cb({ ok = true })
end)

-- Close button or ESC
RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb({})
end)

-- ─────────────────────────────────────────────────────────────────
--  Server → Client events
-- ─────────────────────────────────────────────────────────────────

-- Server response after addToQueue
RegisterNetEvent('crazy-kitchen:queueResponse', function(response)
    SendNUIMessage({ action = 'queueResponse', data = response })
    if not response.ok then
        notify(response.reason, 'error')
    end
end)

-- Server response after cancelQueue
RegisterNetEvent('crazy-kitchen:cancelResponse', function(response)
    SendNUIMessage({ action = 'cancelResponse', data = response })
    if not response.ok then
        notify(response.reason or 'Could not cancel.', 'error')
    else
        notify('Craft cancelled – ingredients returned to storage.', 'inform')
    end
end)

-- Server broadcasts full queue state to all viewers on every change
RegisterNetEvent('crazy-kitchen:queueSync', function(queueData)
    SendNUIMessage({ action = 'queueSync', data = queueData })
end)

-- Craft completed (server authoritative)
RegisterNetEvent('crazy-kitchen:craftComplete', function(data)
    SendNUIMessage({ action = 'craftComplete', data = data })
    if data.dropped then
        notify(data.recipeName .. ' was ready but storage was full – dropped on the floor!', 'warning')
    else
        notify(data.recipeName .. ' is ready in the business storage!', 'success')
    end
end)

-- ─────────────────────────────────────────────────────────────────
--  ESC to close
-- ─────────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if uiOpen and IsControlJustReleased(0, 200) then
            closeUI()
        end
    end
end)
