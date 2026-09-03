--[[
    crazy-register — server.lua
    Crazy RP | ox_inventory | ox_lib | qbx_core
--]]

local activeOrders = {}   -- [orderId] = order table
local tillQueue    = {}   -- [bizKey][tillIndex] = orderId
local orderCounter = 1

-- ─────────────────────────────────────────────────────────────────────────────
-- STORAGE REGISTRATION
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    for bizKey, biz in pairs(Config.Businesses) do
        for i, storage in ipairs(biz.storages or {}) do
            local stashId = 'crazyreg_stash_' .. bizKey .. '_' .. i
            exports.ox_inventory:RegisterStash(
                stashId,
                storage.label,
                storage.slots  or 50,
                storage.weight or 100000
            )
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- DATABASE SETUP
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `crazy_register_bundles` (
            `id`          INT          NOT NULL AUTO_INCREMENT,
            `business`    VARCHAR(64)  NOT NULL,
            `name`        VARCHAR(128) NOT NULL,
            `description` TEXT         NOT NULL,
            `price`       FLOAT        NOT NULL DEFAULT 0,
            `icon`        VARCHAR(128) NOT NULL DEFAULT 'fa-solid fa-box',
            `items`       LONGTEXT     NOT NULL COMMENT 'JSON array of {item, qty}',
            `active`      TINYINT(1)   NOT NULL DEFAULT 1,
            `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_business` (`business`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- Add icon column to existing installs that don't have it yet
    MySQL.query([[
        ALTER TABLE `crazy_register_bundles`
        ADD COLUMN IF NOT EXISTS `icon` VARCHAR(128) NOT NULL DEFAULT 'fa-solid fa-box'
        AFTER `price`;
    ]])
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────────────────
local function getPlayerJob(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        return Player.PlayerData.job.name, Player.PlayerData.job.grade.level
    end
    return nil, 0
end

local function isStaff(src, businessKey)
    local perm = Config.StaffJobPermissions[businessKey]
    if not perm then return false end
    local job, grade = getPlayerJob(src)
    return job == perm.job and grade >= perm.grade
end

local function debugLog(msg)
    if Config.Debug then print('[crazy-register] ' .. msg) end
end

-- Till queue helpers
local function getTillOrder(bizKey, tillIndex)
    if not tillQueue[bizKey] then return nil end
    local orderId = tillQueue[bizKey][tillIndex]
    if not orderId then return nil end
    local order = activeOrders[orderId]
    if not order or order.paid then
        tillQueue[bizKey][tillIndex] = nil
        return nil
    end
    return order
end

local function setTillOrder(bizKey, tillIndex, orderId)
    if not tillQueue[bizKey] then
        tillQueue[bizKey] = {}
    end
    tillQueue[bizKey][tillIndex] = orderId
end

local function clearTillOrder(bizKey, tillIndex)
    if not tillQueue[bizKey] then return end
    local orderId = tillQueue[bizKey][tillIndex]
    if orderId then
        activeOrders[orderId] = nil
        debugLog('Till ' .. tostring(tillIndex) .. ' order #' .. orderId .. ' cleared for ' .. bizKey)
    end
    tillQueue[bizKey][tillIndex] = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CALLBACKS
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register('crazy-register:getProducts', function(_, businessKey)
    local biz = Config.Businesses[businessKey]
    if not biz then return nil end
    return biz.products
end)

lib.callback.register('crazy-register:getBundles', function(_, businessKey)
    local result = MySQL.query.await(
        'SELECT * FROM crazy_register_bundles WHERE business = ?',
        { businessKey }
    )
    if not result then return {} end
    for _, row in ipairs(result) do
        row.items = json.decode(row.items)
    end
    return result
end)

-- Returns the pending order for a specific business till (nil if none)
lib.callback.register('crazy-register:getBusinessOrder', function(_, bizKey, tillIndex)
    return getTillOrder(bizKey, tillIndex)
end)

lib.callback.register('crazy-register:createBundle', function(src, data)
    if not isStaff(src, data.business) then
        debugLog('createBundle: permission denied for src ' .. src)
        return false, 'No permission'
    end
    local biz = Config.Businesses[data.business]
    if not biz then return false, 'Invalid business' end
    if not data.name or data.name == '' then return false, 'Name required' end
    if not biz.serviceOnly then
        if not data.items or #data.items == 0 then return false, 'No items selected' end
    end

    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM crazy_register_bundles WHERE business = ?',
        { data.business }
    )
    if count >= Config.MaxBundlesPerBiz then
        return false, 'Max bundles reached (' .. Config.MaxBundlesPerBiz .. ')'
    end

    MySQL.insert.await(
        'INSERT INTO crazy_register_bundles (business, name, description, price, icon, items, active) VALUES (?,?,?,?,?,?,1)',
        { data.business, data.name, data.description or '', data.price or 0, data.icon or 'fa-solid fa-box', json.encode(data.items or {}) }
    )
    debugLog('Bundle created: ' .. data.name .. ' for ' .. data.business)
    return true
end)

lib.callback.register('crazy-register:deleteBundle', function(src, data)
    if not isStaff(src, data.business) then return false, 'No permission' end
    MySQL.query.await('DELETE FROM crazy_register_bundles WHERE id = ? AND business = ?', { data.id, data.business })
    return true
end)

lib.callback.register('crazy-register:toggleBundle', function(src, data)
    if not isStaff(src, data.business) then return false, 'No permission' end
    MySQL.query.await(
        'UPDATE crazy_register_bundles SET active = NOT active WHERE id = ? AND business = ?',
        { data.id, data.business }
    )
    return true
end)

lib.callback.register('crazy-register:editBundle', function(src, data)
    if not isStaff(src, data.business) then return false, 'No permission' end
    MySQL.query.await(
        'UPDATE crazy_register_bundles SET name=?, description=?, price=?, icon=?, items=? WHERE id=? AND business=?',
        { data.name, data.description, data.price, data.icon or 'fa-solid fa-box', json.encode(data.items), data.id, data.business }
    )
    return true
end)

-- Place an order — queues it to the specific till's pay terminal
lib.callback.register('crazy-register:placeOrder', function(src, data)
    if not isStaff(src, data.business) then return false, 'No permission' end

    local biz       = Config.Businesses[data.business]
    local tillIndex = data.tillIndex
    if not biz then return false, 'Invalid business' end
    if not tillIndex then return false, 'No till specified' end
    if not data.cartBundles or #data.cartBundles == 0 then return false, 'Cart is empty' end

    -- Block if this till already has an unpaid order
    if getTillOrder(data.business, tillIndex) then
        return false, 'This till already has a pending order'
    end

    local orderBundles = {}
    local orderItems   = {}
    local total        = 0

    for _, cb in ipairs(data.cartBundles) do
        local row = MySQL.single.await(
            'SELECT * FROM crazy_register_bundles WHERE id = ? AND business = ? AND active = 1',
            { cb.bundleId, data.business }
        )
        if row then
            local bundleQty = math.max(1, math.floor(cb.qty or 1))
            local items     = json.decode(row.items)
            table.insert(orderBundles, {
                id          = row.id,
                name        = row.name,
                description = row.description or '',
                icon        = row.icon or '',
                items       = items,
                price       = row.price * bundleQty,
                qty         = bundleQty,
            })
            for _, itm in ipairs(items) do
                table.insert(orderItems, { item = itm.item, qty = itm.qty * bundleQty })
            end
            total = total + (row.price * bundleQty)
        end
    end

    if #orderBundles == 0 then return false, 'No valid bundles in cart' end

    local orderId = orderCounter
    orderCounter  = orderCounter + 1

    activeOrders[orderId] = {
        id        = orderId,
        business  = data.business,
        tillIndex = tillIndex,
        bizLabel  = biz.label,
        bundles   = orderBundles,
        items     = orderItems,
        total     = total,
        staffSrc  = src,
        paid      = false,
    }

    setTillOrder(data.business, tillIndex, orderId)

    debugLog('Order #' .. orderId .. ' queued on till ' .. tillIndex .. ' | biz: ' .. data.business .. ' | total: $' .. total)
    return true, orderId
end)

-- Staff clears the pending order from a till (e.g. customer mistake)
lib.callback.register('crazy-register:clearOrder', function(src, data)
    if not isStaff(src, data.business) then return false, 'No permission' end
    clearTillOrder(data.business, data.tillIndex)
    return true
end)

-- Customer pays for the pending order at their terminal
lib.callback.register('crazy-register:payOrder', function(src, data)
    local order = activeOrders[data.orderId]
    if not order then return false, 'Order not found' end
    if order.paid then return false, 'Already paid' end

    local method = data.method

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false, 'Player not found' end

    local balance = method == 'cash' and Player.PlayerData.money.cash or Player.PlayerData.money.bank
    if balance < order.total then
        return false, 'Insufficient funds'
    end

    local bundleNames = {}
    for _, b in ipairs(order.bundles) do
        bundleNames[#bundleNames + 1] = b.name .. (b.qty > 1 and ' x' .. b.qty or '')
    end
    local purchaseDesc = order.bizLabel .. ': ' .. table.concat(bundleNames, ', ')
    Player.Functions.RemoveMoney(method, order.total, purchaseDesc)

    -- Items are NOT given automatically — staff hand them over separately
    order.paid = true

    -- Clear this till's queue
    clearTillOrder(order.business, order.tillIndex)
    activeOrders[data.orderId] = nil

    -- Pay the staff member who took the order their cut directly, in place
    -- of the original prp_tablet:recordSale commission tracker.
    local commission, commPct
    if order.staffSrc and order.staffSrc > 0 and order.total > 0 then
        commPct = Config.CommissionPercent or 0
        if commPct > 0 then
            commission = math.floor(order.total * (commPct / 100) + 0.5)
            if commission > 0 then
                local StaffPlayer = exports.qbx_core:GetPlayer(order.staffSrc)
                if StaffPlayer then
                    StaffPlayer.Functions.AddMoney('cash', commission, order.bizLabel .. ' commission')
                end
            end
        end
    end

    -- Notify staff with commission info if available
    if order.staffSrc and order.staffSrc > 0 then
        TriggerClientEvent('crazy-register:orderPaid', order.staffSrc, {
            orderId    = data.orderId,
            total      = order.total,
            commission = commission,
            commPct    = commPct,
        })
    end

    debugLog('Order #' .. data.orderId .. ' PAID | method: ' .. method .. ' | src: ' .. src)
    return true
end)

-- Self-service bundle order from menu board (kept for potential future use)
lib.callback.register('crazy-register:orderBundle', function(src, data)
    local bundleRow = MySQL.single.await(
        'SELECT * FROM crazy_register_bundles WHERE id=? AND business=? AND active=1',
        { data.bundleId, data.business }
    )
    if not bundleRow then return false, 'Bundle not found or inactive' end

    local items  = json.decode(bundleRow.items)
    local total  = bundleRow.price
    local method = data.method

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false, 'Player not found' end

    local balance = method == 'cash' and Player.PlayerData.money.cash or Player.PlayerData.money.bank
    if balance < total then return false, 'Insufficient funds' end

    Player.Functions.RemoveMoney(method, total, data.business .. ': ' .. bundleRow.name)

    for _, bi in ipairs(items) do
        exports.ox_inventory:AddItem(src, bi.item, bi.qty)
    end

    debugLog('Bundle #' .. data.bundleId .. ' purchased by src ' .. src)
    return true
end)
