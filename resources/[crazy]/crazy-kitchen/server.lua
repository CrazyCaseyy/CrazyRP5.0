--[[ ══════════════════════════════════════════════════════════════
     Crazy Kitchen Stations – Server
     ══════════════════════════════════════════════════════════════ ]]

-- ─────────────────────────────────────────────────────────────────
--  State
--  activeQueues[stationId] = { crafting = bool, queue = { ... } }
-- ─────────────────────────────────────────────────────────────────
local activeQueues   = {}
local stationViewers = {} -- [stationId] = { [src] = true }

-- ─────────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────────

local function getStation(stationId)
    for _, s in ipairs(Config.Stations) do
        if s.id == stationId then return s end
    end
end

local function getRecipe(station, recipeId)
    for _, r in ipairs(station.recipes) do
        if r.id == recipeId then return r end
    end
end

local function stashName(stationId)
    return 'craft_' .. stationId
end

-- Broadcast authoritative queue state to every player viewing this station
local function broadcastQueue(stationId)
    local sq = activeQueues[stationId]
    if not sq then return end
    local queueData = {}
    for i, item in ipairs(sq.queue) do
        local isActive = (i == 1 and sq.crafting)
        queueData[#queueData + 1] = {
            queueId    = item.queueId,
            recipeId   = item.recipe.id,
            recipeName = item.recipe.name,
            qty        = item.qty,
            crafting   = isActive,
            elapsedMs  = isActive and item.startedAt and ((os.time() - item.startedAt) * 1000) or 0,
        }
    end
    for src in pairs(stationViewers[stationId] or {}) do
        TriggerClientEvent('crazy-kitchen:queueSync', src, queueData)
    end
end

local function ensureStash(station)
    exports.ox_inventory:RegisterStash(
        stashName(station.id),
        station.label .. ' Storage',
        station.stashSlots,
        station.stashWeight
    )
end

local function getPlayerJob(src)
    local player = exports.qbx_core:GetPlayer(src)
    if player then return player.PlayerData.job end
    return nil
end

local function hasJob(src, jobName)
    local job = getPlayerJob(src)
    return job and job.name == jobName
end

local function countStashItem(stationId, itemName)
    local total = 0
    local items = exports.ox_inventory:GetInventoryItems(stashName(stationId)) or {}
    for _, slot in pairs(items) do
        if slot and slot.name == itemName then
            total = total + slot.count
        end
    end
    return total
end

local function removeStashItems(stationId, itemName, qty)
    return exports.ox_inventory:RemoveItem(stashName(stationId), itemName, qty)
end

local function addStashItem(stationId, itemName, qty)
    local ok, reason = exports.ox_inventory:AddItem(stashName(stationId), itemName, qty)
    if not ok then
        print(('[crazy-kitchen] AddItem failed for "%s" x%d in %s: %s'):format(itemName, qty, stashName(stationId), tostring(reason)))
    end
    return ok, reason
end

local function dropItemAtStation(station, itemName, qty)
    local coords = station.coords + Config.DropOffset
    exports.ox_inventory:CustomDrop(
        'Kitchen Drop',
        { { itemName, qty } },
        coords
    )
    print(('[crazy-kitchen] Stash full — dropped %dx %s at station %s'):format(qty, itemName, station.id))
end

-- ─────────────────────────────────────────────────────────────────
--  Register stashes on resource start
-- ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, station in ipairs(Config.Stations) do
        ensureStash(station)
        activeQueues[station.id]   = { crafting = false, queue = {}, generation = 0 }
        stationViewers[station.id] = {}
        print(('[crazy-kitchen] Registered kitchen stash: %s'):format(stashName(station.id)))
    end
end)

-- Track which players have the UI open for each station
RegisterNetEvent('crazy-kitchen:registerViewer', function(stationId)
    local src = source
    if stationViewers[stationId] then
        stationViewers[stationId][src] = true
    end
end)

RegisterNetEvent('crazy-kitchen:unregisterViewer', function(stationId)
    local src = source
    if stationViewers[stationId] then
        stationViewers[stationId][src] = nil
    end
end)

-- Clean up if a player disconnects while viewing
AddEventHandler('playerDropped', function()
    local src = source
    for _, viewers in pairs(stationViewers) do
        viewers[src] = nil
    end
end)

-- ─────────────────────────────────────────────────────────────────
--  Open stash (Kitchen Storage target)
-- ─────────────────────────────────────────────────────────────────

RegisterNetEvent('crazy-kitchen:openStash', function(stationId)
    local src     = source
    local station = getStation(stationId)
    if not station then return end

    -- Job check server-side
    if not hasJob(src, station.job) then
        print(('[crazy-kitchen] Player %d tried to open stash %s without correct job'):format(src, stationId))
        return
    end

    ensureStash(station)
    TriggerClientEvent('crazy-kitchen:openStashClient', src, stashName(stationId))
end)

-- ─────────────────────────────────────────────────────────────────
--  Order Supplies — buy raw ingredients into the business stash
-- ─────────────────────────────────────────────────────────────────

local function getSupplyEntry(station, itemName)
    for _, entry in ipairs(station.supplies or {}) do
        if entry.item == itemName then return entry end
    end
end

RegisterNetEvent('crazy-kitchen:buySupply', function(data)
    local src     = source
    local station = getStation(data.stationId)
    if not station then return end

    -- Guarantee the stash is registered before touching it - onResourceStart
    -- only runs once at boot, so a stash that was never opened via the
    -- storage target could still be unregistered if that startup event was
    -- ever missed (e.g. a hot reload rather than a full resource restart).
    ensureStash(station)

    if not hasJob(src, station.job) then
        TriggerClientEvent('crazy-kitchen:buySupplyResponse', src, { ok = false, reason = 'You are not employed here.' })
        return
    end

    -- Never trust a client-sent price - look the item up in the station's own catalog
    local entry = getSupplyEntry(station, data.item)
    if not entry then
        TriggerClientEvent('crazy-kitchen:buySupplyResponse', src, { ok = false, reason = 'That item is not sold here.' })
        return
    end

    local qty    = math.max(1, math.floor(tonumber(data.qty) or 1))
    local method = (data.method == 'bank') and 'bank' or 'cash'
    local total  = entry.price * qty

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local balance = method == 'cash' and player.PlayerData.money.cash or player.PlayerData.money.bank
    if balance < total then
        TriggerClientEvent('crazy-kitchen:buySupplyResponse', src, {
            ok     = false,
            reason = ('Not enough %s. Need $%d.'):format(method, total),
        })
        return
    end

    player.Functions.RemoveMoney(method, total, station.label .. ' supply order')

    local itemData = exports.ox_inventory:Items(entry.item)
    local label    = itemData and itemData.label or entry.item

    local added, failReason = addStashItem(data.stationId, entry.item, qty)
    if not added then
        -- Refund the purchase rather than losing the money
        player.Functions.AddMoney(method, total, 'Supply order refund (' .. tostring(failReason) .. ')')
        local reasonText = failReason == 'invalid_item'
            and 'That item is not registered on this server yet - purchase refunded.'
            or 'Storage is full - purchase refunded.'
        TriggerClientEvent('crazy-kitchen:buySupplyResponse', src, {
            ok     = false,
            reason = reasonText,
        })
        return
    end

    TriggerClientEvent('crazy-kitchen:buySupplyResponse', src, {
        ok    = true,
        qty   = qty,
        label = label,
        total = total,
    })
end)

-- ─────────────────────────────────────────────────────────────────
--  Add to Queue
-- ─────────────────────────────────────────────────────────────────

RegisterNetEvent('crazy-kitchen:addToQueue', function(data)
    local src     = source
    local station = getStation(data.stationId)
    if not station then
        TriggerClientEvent('crazy-kitchen:queueResponse', src, { ok = false, reason = 'Station not found.' })
        return
    end

    ensureStash(station)

    -- Server-side job check
    if not hasJob(src, station.job) then
        TriggerClientEvent('crazy-kitchen:queueResponse', src, { ok = false, reason = 'You are not employed here.' })
        return
    end

    local recipe = getRecipe(station, data.recipeId)
    if not recipe then
        TriggerClientEvent('crazy-kitchen:queueResponse', src, { ok = false, reason = 'Recipe not found.' })
        return
    end

    local qty = math.max(1, math.floor(tonumber(data.qty) or 1))

    -- ── 1. Check ingredients in stash ──
    for _, ing in ipairs(recipe.ingredients) do
        local needed = ing.qty * qty
        local have   = countStashItem(data.stationId, ing.item)
        if have < needed then
            local itemData = exports.ox_inventory:Items(ing.item)
            local label    = itemData and itemData.label or ing.item
            TriggerClientEvent('crazy-kitchen:queueResponse', src, {
                ok     = false,
                reason = ('Not enough %s in kitchen storage. Need %d, have %d.'):format(label, needed, have),
            })
            return
        end
    end

    -- ── 2. Remove ingredients immediately ──
    for _, ing in ipairs(recipe.ingredients) do
        if not removeStashItems(data.stationId, ing.item, ing.qty * qty) then
            TriggerClientEvent('crazy-kitchen:queueResponse', src, {
                ok     = false,
                reason = 'Failed to remove ingredients from storage. Please try again.',
            })
            return
        end
    end

    -- ── 3. Build queue entry ──
    local queueId   = tostring(os.time()) .. '_' .. tostring(math.random(1000, 9999))
    local queueItem = {
        queueId   = queueId,
        stationId = data.stationId,
        recipe    = recipe,
        qty       = qty,
        src       = src,
        cancelled = false,
        timerCb   = nil, -- will hold cancel handle
    }

    local sq        = activeQueues[data.stationId]
    table.insert(sq.queue, queueItem)

    -- ── 4. Respond to client (ok/fail only) and sync all viewers ──
    TriggerClientEvent('crazy-kitchen:queueResponse', src, { ok = true })

    -- ── 5. Start queue if idle ──
    if not sq.crafting then
        processQueue(data.stationId)
    end

    broadcastQueue(data.stationId)
end)

-- ─────────────────────────────────────────────────────────────────
--  Cancel Queue Item
--  Only pending (not yet crafting) items can be cancelled.
--  Ingredients are refunded to the stash.
-- ─────────────────────────────────────────────────────────────────

RegisterNetEvent('crazy-kitchen:cancelQueue', function(data)
    local src     = source
    local station = getStation(data.stationId)
    if not station then
        TriggerClientEvent('crazy-kitchen:cancelResponse', src, { ok = false, reason = 'Station not found.' })
        return
    end

    if not hasJob(src, station.job) then
        TriggerClientEvent('crazy-kitchen:cancelResponse', src, { ok = false, reason = 'Not authorised.' })
        return
    end

    local sq = activeQueues[data.stationId]
    if not sq then
        TriggerClientEvent('crazy-kitchen:cancelResponse', src, { ok = false, reason = 'Queue not found.' })
        return
    end

    -- Find the item in the queue
    local itemIdx, item
    for i, q in ipairs(sq.queue) do
        if q.queueId == data.queueId then
            itemIdx = i
            item    = q
            break
        end
    end

    if not item then
        TriggerClientEvent('crazy-kitchen:cancelResponse', src, { ok = false, reason = 'Item not in queue.' })
        return
    end

    -- Mark cancelled and remove from queue
    item.cancelled = true
    table.remove(sq.queue, itemIdx)

    -- Refund ingredients to stash
    local refundFailed = false
    for _, ing in ipairs(item.recipe.ingredients) do
        local refundQty = ing.qty * item.qty
        local added     = addStashItem(data.stationId, ing.item, refundQty)
        if not added then
            -- Stash full – drop on floor
            refundFailed = true
            if station then
                dropItemAtStation(station, ing.item, refundQty)
            end
        end
    end

    if refundFailed then
        TriggerClientEvent('crazy-kitchen:cancelResponse', src, {
            ok      = true,
            queueId = data.queueId,
            warning = 'Some ingredients were dropped on the floor as the storage was full.',
        })
    else
        TriggerClientEvent('crazy-kitchen:cancelResponse', src, {
            ok      = true,
            queueId = data.queueId,
        })
    end

    -- If the active item was cancelled, bump the generation to invalidate its
    -- SetTimeout and immediately start the next item in the queue.
    if itemIdx == 1 and sq.crafting then
        sq.generation = sq.generation + 1
        sq.crafting   = false
        processQueue(data.stationId)
    end

    broadcastQueue(data.stationId)
end)

-- ─────────────────────────────────────────────────────────────────
--  Get current queue (called when player reopens the UI)
-- ─────────────────────────────────────────────────────────────────

lib.callback.register('crazy-kitchen:getQueue', function(_, stationId)
    local sq = activeQueues[stationId]
    if not sq then return {} end
    local result = {}
    for i, item in ipairs(sq.queue) do
        local isActive = (i == 1 and sq.crafting)
        result[#result + 1] = {
            queueId   = item.queueId,
            recipeId  = item.recipe.id,
            qty       = item.qty,
            crafting  = isActive,
            elapsedMs = isActive and item.startedAt and ((os.time() - item.startedAt) * 1000) or 0,
        }
    end
    return result
end)

-- ─────────────────────────────────────────────────────────────────
--  Queue Processor – one item at a time per station
-- ─────────────────────────────────────────────────────────────────

processQueue = function(stationId)
    local sq = activeQueues[stationId]
    if not sq then return end
    if #sq.queue == 0 then
        sq.crafting = false
        broadcastQueue(stationId)
        return
    end

    sq.crafting    = true
    local item     = sq.queue[1]
    local station  = getStation(stationId)
    local totalMs  = (item.recipe.craftTime * item.qty) * 1000
    local myGen    = sq.generation
    item.startedAt = os.time()

    SetTimeout(totalMs, function()
        -- Cancelled or superseded by a newer processQueue call — bail out silently
        if item.cancelled or sq.generation ~= myGen then
            return
        end

        local ok, err = pcall(function()
            -- Remove from queue
            table.remove(sq.queue, 1)

            -- Attempt to add output item to stash
            local outputItem = item.recipe.output
            local outputQty  = item.recipe.yield * item.qty

            local added      = addStashItem(stationId, outputItem, outputQty)
            local dropped    = false

            -- ox_inventory:AddItem returns a slot number (truthy) on success, false/nil on failure
            if not added or added == 0 then
                dropped = true
                dropItemAtStation(station or getStation(stationId), outputItem, outputQty)
            end

            -- Notify the player who queued the item (personal notification only)
            TriggerClientEvent('crazy-kitchen:craftComplete', item.src, {
                queueId    = item.queueId,
                recipeId   = item.recipe.id,
                recipeName = item.recipe.name,
                stationId  = stationId,
                dropped    = dropped,
            })
        end)

        if not ok then
            print(('[crazy-kitchen] ERROR in craft completion for %s: %s'):format(item.recipe.id, tostring(err)))
        end

        -- Process next item then sync all viewers
        processQueue(stationId)
        broadcastQueue(stationId)
    end)
end
