--[[
    crazy-register — client.lua
    Crazy RP | ox_target (box zones) | ox_lib | qbx_core
--]]

local currentBusiness = nil
local currentTill     = nil  -- till index (integer) for multi-till support

-- Forward declarations
local openRegister, openPayTerminal, openCustomerMenu

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

local function debugLog(msg)
    if Config.Debug then
        print('^3[crazy-register] ^7' .. tostring(msg))
    end
end

local function getPlayerJob()
    local job = QBX.PlayerData.job
    if job then
        return job.name, job.grade.level
    end
    return 'unemployed', 0
end

local function isStaffFor(businessKey)
    local perm = Config.StaffJobPermissions[businessKey]
    if not perm then return true end
    local job, grade = getPlayerJob()
    debugLog('Job check: player=' .. tostring(job) .. '/' .. tostring(grade) .. ' required=' .. perm.job .. '/' .. perm.grade)
    if job ~= perm.job or grade < perm.grade then return false end
    -- Must also be on duty to use the register
    return QBX.PlayerData.job.onduty
end

local function sendNUI(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function openNUI()
    SetNuiFocus(true, true)
    debugLog('NUI opened')
end

local function closeNUI()
    currentBusiness = nil
    currentTill     = nil
    SetNuiFocus(false, false)
    sendNUI('close', {})
    debugLog('NUI closed')
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ox_target BOX ZONES
--
-- Each business can have multiple tills (biz.tills = array of register+terminal pairs)
-- and multiple menu boards (biz.menuZones = array of zone configs).
--
-- Each register is paired with its own pay terminal via the till index,
-- so orders from till 1 only appear on terminal 1, etc.
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    for bizKey, biz in pairs(Config.Businesses) do
        debugLog('Registering zones for: ' .. bizKey)

        -- ── REGISTER + PAY TERMINAL PAIRS ────────────────────────────────────
        for i, till in ipairs(biz.tills) do
            local tillLabel = #biz.tills > 1 and (' — Till ' .. i) or ''

            -- Staff register zone
            local rz = till.registerZone
            exports.ox_target:addBoxZone({
                coords   = rz.coords,
                size     = rz.size,
                rotation = rz.heading,
                debug    = Config.Debug,
                options  = {
                    {
                        name        = 'crazyreg_' .. bizKey .. '_' .. i,
                        label       = 'Use Register',
                        icon        = 'fas fa-cash-register',
                        distance    = 2.5,
                        canInteract = function() return isStaffFor(bizKey) end,
                        onSelect    = function()
                            debugLog('Register zone triggered: ' .. bizKey .. ' till ' .. i)
                            openRegister(bizKey, i)
                        end,
                    },
                },
            })

            -- Customer pay terminal — prop-based target
            local pp = till.payTerminalProp
            if pp then
                local model = pp.model
                RequestModel(model)
                local t = 0
                while not HasModelLoaded(model) do
                    Wait(100); t = t + 1
                    if t > 50 then debugLog('WARN: model failed to load (pay terminal): ' .. tostring(model)); break end
                end

                if HasModelLoaded(model) then
                    local prop = CreateObjectNoOffset(
                        model,
                        pp.coords.x, pp.coords.y, pp.coords.z,
                        false, false, false
                    )
                    SetEntityHeading(prop, pp.coords.w)
                    SetEntityCollision(prop, true, true)
                    FreezeEntityPosition(prop, true)
                    SetEntityInvincible(prop, true)
                    SetModelAsNoLongerNeeded(model)

                    exports.ox_target:addLocalEntity(prop, {
                        {
                            name     = 'crazypay_' .. bizKey .. '_' .. i,
                            label    = 'Pay Terminal',
                            icon     = 'fas fa-credit-card',
                            distance = 2.5,
                            onSelect = function()
                                debugLog('Pay terminal prop triggered: ' .. bizKey .. ' till ' .. i)
                                openPayTerminal(bizKey, i)
                            end,
                        },
                    })
                end
            end
        end

        -- ── MENU BOARD PROPS (prop-based target, same as pay terminal) ──────
        for i, mp in ipairs(biz.menuProps or {}) do
            local model = mp.model
            RequestModel(model)
            local t = 0
            while not HasModelLoaded(model) do
                Wait(100); t = t + 1
                if t > 50 then debugLog('WARN: model failed to load (menu prop): ' .. tostring(model)); break end
            end

            if HasModelLoaded(model) then
                local prop = CreateObjectNoOffset(
                    model,
                    mp.coords.x, mp.coords.y, mp.coords.z,
                    false, false, false
                )
                SetEntityHeading(prop, mp.coords.w)
                SetEntityCollision(prop, true, true)
                FreezeEntityPosition(prop, true)
                SetEntityInvincible(prop, true)
                SetModelAsNoLongerNeeded(model)

                exports.ox_target:addLocalEntity(prop, {
                    {
                        name     = 'crazymenu_' .. bizKey .. '_' .. i,
                        label    = 'View Menu',
                        icon     = 'fas fa-utensils',
                        distance = 3.0,
                        onSelect = function()
                            debugLog('Menu prop triggered: ' .. bizKey)
                            openCustomerMenu(bizKey)
                        end,
                    },
                })
                debugLog('Menu prop spawned for: ' .. bizKey .. ' (' .. i .. ')')
            end
        end

        -- ── BLIP ──────────────────────────────────────────────────────────────
        if biz.blip then
            local blipCoords = biz.blip.coords or (biz.tills[1] and biz.tills[1].registerZone.coords)
            if blipCoords then
                local blip = AddBlipForCoord(blipCoords.x, blipCoords.y, blipCoords.z)
                SetBlipSprite(blip, biz.blip.sprite or 52)
                SetBlipColour(blip, biz.blip.colour or 2)
                SetBlipScale(blip, 0.8)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(biz.label)
                EndTextCommandSetBlipName(blip)
                debugLog('Blip created for: ' .. bizKey)
            end
        end

        -- ── STORAGE ZONES ─────────────────────────────────────────────────────
        for i, storage in ipairs(biz.storages or {}) do
            local stashId = 'crazyreg_stash_' .. bizKey .. '_' .. i
            exports.ox_target:addBoxZone({
                coords   = storage.coords,
                size     = storage.size,
                rotation = storage.heading,
                debug    = Config.Debug,
                options  = {
                    {
                        name        = 'crazystash_' .. bizKey .. '_' .. i,
                        label       = storage.label,
                        icon        = 'fas fa-box-open',
                        distance    = 2.5,
                        canInteract = function()
                            if storage.staffOnly == false then return true end
                            return isStaffFor(bizKey)
                        end,
                        onSelect    = function()
                            debugLog('Opening storage: ' .. stashId)
                            exports.ox_inventory:openInventory('stash', stashId)
                        end,
                    },
                },
            })
        end
    end

    debugLog('All zones registered.')
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- OPEN REGISTER (STAFF)
-- ─────────────────────────────────────────────────────────────────────────────
openRegister = function(bizKey, tillIndex)
    local biz = Config.Businesses[bizKey]
    debugLog('Opening register for: ' .. bizKey .. ' till ' .. tillIndex)

    local products     = lib.callback.await('crazy-register:getProducts',     false, bizKey)
    local bundles      = lib.callback.await('crazy-register:getBundles',      false, bizKey)
    local pendingOrder = lib.callback.await('crazy-register:getBusinessOrder', false, bizKey, tillIndex)

    if not products then
        lib.notify({ title = 'Register', description = 'Failed to load products.', type = 'error' })
        return
    end

    currentBusiness = bizKey
    currentTill     = tillIndex
    openNUI()
    sendNUI('openRegister', {
        business     = bizKey,
        tillIndex    = tillIndex,
        bizLabel     = biz.label,
        products     = products,
        bundles      = bundles or {},
        isStaff      = true,
        pendingOrder = pendingOrder,
        serviceOnly  = biz.serviceOnly or false,
        iconItems    = biz.iconItems or {},
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- OPEN PAY TERMINAL (CUSTOMER)
-- Fetches the pending order for this specific till
-- ─────────────────────────────────────────────────────────────────────────────
openPayTerminal = function(bizKey, tillIndex)
    local biz   = Config.Businesses[bizKey]
    local order = lib.callback.await('crazy-register:getBusinessOrder', false, bizKey, tillIndex)

    currentBusiness = bizKey
    currentTill     = tillIndex
    openNUI()
    sendNUI('openPayTerminal', {
        business  = bizKey,
        tillIndex = tillIndex,
        bizLabel  = biz.label,
        order     = order,
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- OPEN CUSTOMER MENU (browse-only)
-- ─────────────────────────────────────────────────────────────────────────────
openCustomerMenu = function(bizKey)
    local biz     = Config.Businesses[bizKey]
    local bundles = lib.callback.await('crazy-register:getBundles', false, bizKey)

    local active = {}
    for _, b in ipairs(bundles or {}) do
        if b.active == 1 or b.active == true then
            table.insert(active, b)
        end
    end

    if #active == 0 then
        lib.notify({
            title       = biz.label,
            description = 'No menu items available right now.',
            type        = 'inform',
        })
        return
    end

    currentBusiness = bizKey
    openNUI()
    sendNUI('openMenu', {
        business = bizKey,
        bizLabel = biz.label,
        bundles  = active,
        products = biz.products,
        isStaff  = false,
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NUI CALLBACKS
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    closeNUI()
    cb('ok')
end)

RegisterNUICallback('notify', function(data, cb)
    lib.notify({
        title       = data.title or '',
        description = data.description,
        type        = data.type or 'inform',
    })
    cb('ok')
end)

RegisterNUICallback('placeOrder', function(data, cb)
    local ok, result = lib.callback.await('crazy-register:placeOrder', false, {
        business    = currentBusiness,
        tillIndex   = currentTill,
        cartBundles = data.cartBundles,
    })
    if ok then
        lib.notify({ title = 'Register', description = 'Order queued at terminal!', type = 'success' })
    else
        lib.notify({ title = 'Register', description = tostring(result) or 'Failed to place order.', type = 'error' })
    end
    cb({ ok = ok, orderId = result })
end)

RegisterNUICallback('clearOrder', function(_, cb)
    if not currentBusiness or not currentTill then cb({ ok = false }); return end
    local ok = lib.callback.await('crazy-register:clearOrder', false, {
        business  = currentBusiness,
        tillIndex = currentTill,
    })
    if ok then
        lib.notify({ title = 'Register', description = 'Order cleared from terminal.', type = 'success' })
    end
    cb({ ok = ok })
end)

RegisterNUICallback('createBundle', function(data, cb)
    local ok, err = lib.callback.await('crazy-register:createBundle', false, {
        business    = currentBusiness,
        name        = data.name,
        description = data.description,
        price       = data.price,
        icon        = data.icon,
        items       = data.items,
    })
    if ok then
        lib.notify({ title = 'Bundles', description = 'Bundle "' .. data.name .. '" created!', type = 'success' })
        local bundles = lib.callback.await('crazy-register:getBundles', false, currentBusiness)
        sendNUI('refreshBundles', { bundles = bundles or {} })
    else
        lib.notify({ title = 'Bundles', description = tostring(err) or 'Failed to create bundle.', type = 'error' })
    end
    cb({ ok = ok })
end)

RegisterNUICallback('deleteBundle', function(data, cb)
    local ok, err = lib.callback.await('crazy-register:deleteBundle', false, {
        business = currentBusiness,
        id       = data.id,
    })
    if ok then
        lib.notify({ title = 'Bundles', description = 'Bundle deleted.', type = 'success' })
        local bundles = lib.callback.await('crazy-register:getBundles', false, currentBusiness)
        sendNUI('refreshBundles', { bundles = bundles or {} })
    else
        lib.notify({ title = 'Bundles', description = tostring(err) or 'Failed.', type = 'error' })
    end
    cb({ ok = ok })
end)

RegisterNUICallback('toggleBundle', function(data, cb)
    local ok = lib.callback.await('crazy-register:toggleBundle', false, {
        business = currentBusiness,
        id       = data.id,
    })
    if ok then
        local bundles = lib.callback.await('crazy-register:getBundles', false, currentBusiness)
        sendNUI('refreshBundles', { bundles = bundles or {} })
    end
    cb({ ok = ok })
end)

RegisterNUICallback('editBundle', function(data, cb)
    local ok, err = lib.callback.await('crazy-register:editBundle', false, {
        business    = currentBusiness,
        id          = data.id,
        name        = data.name,
        description = data.description,
        price       = data.price,
        icon        = data.icon,
        items       = data.items,
    })
    if ok then
        lib.notify({ title = 'Bundles', description = 'Bundle updated.', type = 'success' })
        local bundles = lib.callback.await('crazy-register:getBundles', false, currentBusiness)
        sendNUI('refreshBundles', { bundles = bundles or {} })
    else
        lib.notify({ title = 'Bundles', description = tostring(err) or 'Failed.', type = 'error' })
    end
    cb({ ok = ok })
end)

RegisterNUICallback('payOrder', function(data, cb)
    local ok, err = lib.callback.await('crazy-register:payOrder', false, {
        orderId = data.orderId,
        method  = data.method,
    })
    if ok then
        lib.notify({ title = 'Payment', description = 'Payment successful!', type = 'success' })
        closeNUI()
    else
        lib.notify({ title = 'Payment', description = tostring(err) or 'Payment failed.', type = 'error' })
    end
    cb({ ok = ok })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVER → CLIENT EVENTS
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent('crazy-register:orderPaid', function(data)
    local desc = 'Order #' .. data.orderId .. ' paid — $' .. data.total
    if data.commission and data.commission > 0 then
        desc = desc .. ' | Commission: $' .. data.commission
    end
    lib.notify({
        title       = 'Register',
        description = desc,
        type        = 'success',
    })
end)
