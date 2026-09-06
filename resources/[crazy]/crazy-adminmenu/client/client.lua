-- NUI dashboard for server administration. This used to be a thin
-- front-end calling into a separate qbx_adminmenu resource's exports and
-- events; that resource was merged in here (see client/toggles.lua,
-- client/vectors.lua, client/events.lua, server/admin.lua,
-- server/commands.lua) once its own original ox_lib menu was confirmed
-- fully dead code with this NUI as the only front-end left.
--
-- The internal event/callback names (qbx_admin:server:*, qbx_admin:client:*)
-- were kept as-is rather than renamed during the merge - they're just
-- wire names now, harmless to leave, and renaming everything would have
-- widened the diff for no real benefit.
--
-- The purely-client-local toggles (noclip, godmode, invisible, vehicle
-- godmode, infinite ammo, cuff, ped model, coords/vehicle-info overlays,
-- laser pointer) live in client/toggles.lua as plain global functions -
-- same resource now, so no exports() indirection is needed to reach them.
--
-- Ban logs and character lookup never had qbx_adminmenu server logic to
-- begin with, so those NUI callbacks talk to the crazy_adminmenu:server:*
-- section of server/server.lua instead.

local isOpen = false

local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function pushToggleState()
    local ok, adminState = pcall(GetAdminToggleState)
    local ok2, devState = pcall(GetDevToggleState)
    SendNUIMessage({
        action = 'toggleState',
        state = {
            noclip = ok and adminState.noclip or false,
            invisible = ok and adminState.invisible or false,
            godmode = ok and adminState.godmode or false,
            vehicleGodmode = ok and adminState.vehicleGodmode or false,
            infiniteAmmo = ok and adminState.infiniteAmmo or false,
            names = ok and adminState.names or false,
            blips = ok and adminState.blips or false,
            coords = ok2 and devState.coords or false,
            vehicleInfo = ok2 and devState.vehicleInfo or false,
            laser = ok2 and devState.laser or false,
        }
    })
end

local function open()
    if isOpen then return end

    local canUse = lib.callback.await('qbx_admin:server:canUseMenu', false)
    if not canUse then return end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    pushToggleState()
end

RegisterNetEvent('qbx_admin:client:openMenu', function()
    if GetInvokingResource() then return end
    open()
end)

RegisterCommand('crazy_adminmenu_open', function()
    open()
end, false)

RegisterNUICallback('close', function(_, cb)
    close()
    cb('ok')
end)

-- ===================================================================
-- Players
-- ===================================================================

RegisterNUICallback('getPlayers', function(_, cb)
    local players = lib.callback.await('qbx_admin:server:getPlayers', false)
    cb(players or {})
end)

RegisterNUICallback('getPlayerDetail', function(data, cb)
    local player = lib.callback.await('qbx_admin:server:getPlayer', false, data.id)
    cb(player)
end)

RegisterNUICallback('getDashboardStats', function(_, cb)
    local stats = lib.callback.await('crazy_adminmenu:server:getDashboardStats', false)
    cb(stats or { playerCount = 0, jobCounts = {} })
end)

RegisterNUICallback('getPlayerHistory', function(_, cb)
    local rows = lib.callback.await('crazy_adminmenu:server:getPlayerHistory', false)
    cb(rows or {})
end)

RegisterNUICallback('getJobsAndGangs', function(_, cb)
    local data = lib.callback.await('crazy_adminmenu:server:getJobsAndGangs', false)
    cb(data or { jobs = {}, gangs = {} })
end)

-- Matches the index order qbx_adminmenu's generalOptions table uses
-- (server/main.lua) — kill/revive/freeze/goto/bring/sit. Index 7 there is
-- routing bucket, deliberately left out of this map - not exposed here.
local GENERAL_ACTIONS = {
    kill = 1, revive = 2, freeze = 3, goto_ = 4, bring = 5, sit = 6,
}

RegisterNUICallback('playerGeneral', function(data, cb)
    local index = GENERAL_ACTIONS[data.action]
    if not index then cb('error') return end
    TriggerServerEvent('qbx_admin:server:playerOptionsGeneral', index, { id = data.id }, data.input)
    cb('ok')
end)

-- Matches qbx_adminmenu's administrationOptions index order: kick/ban.
-- (index 3, "perm", used to call qbx_core's own deprecated
-- AddPermission/RemovePermission - removed along with its handler, see
-- server/admin.lua's administrationOptions.)
local ADMIN_ACTIONS = { kick = 1, ban = 2 }

RegisterNUICallback('playerAdmin', function(data, cb)
    local index = ADMIN_ACTIONS[data.action]
    if not index then cb('error') return end
    TriggerServerEvent('qbx_admin:server:playerAdministration', index, { id = data.id }, data.input)
    cb('ok')
end)

RegisterNUICallback('changePlayerData', function(data, cb)
    TriggerServerEvent('qbx_admin:server:changePlayerData', data.field, { id = data.id }, data.input)
    cb('ok')
end)

RegisterNUICallback('clothingMenu', function(data, cb)
    local ok = lib.callback.await('qbx_admin:server:clothingMenu', false, data.id)
    cb(ok or false)
end)

RegisterNUICallback('giveItem', function(data, cb)
    if data.item and data.item ~= '' and tonumber(data.amount) and tonumber(data.amount) > 0 then
        ExecuteCommand(('giveitem %s %s %s'):format(data.id, data.item, data.amount))
    end
    cb('ok')
end)

-- Mirrors giveItem above but for ox_inventory's own /removeitem command -
-- same admin-restricted command the give side already leans on, just the
-- remove half of the same pair.
RegisterNUICallback('removePlayerItem', function(data, cb)
    if data.item and data.item ~= '' and tonumber(data.amount) and tonumber(data.amount) > 0 then
        ExecuteCommand(('removeitem %s %s %s'):format(data.id, data.item, data.amount))
    end
    cb('ok')
end)

RegisterNUICallback('getPlayerInventory', function(data, cb)
    local items = lib.callback.await('crazy_adminmenu:server:getPlayerInventory', false, data.id)
    cb(items or {})
end)

-- CEF's clipboard access from JS is unreliable without a real user
-- gesture in this context, so route through ox_lib's native clipboard
-- helper the same way the original ox_lib menu did (lib.setClipboard).
RegisterNUICallback('copyText', function(data, cb)
    if data.value and data.value ~= '' then
        lib.setClipboard(tostring(data.value))
    end
    cb('ok')
end)

-- ===================================================================
-- Self tools (admin.lua / dev.lua toggles reached via exports)
-- ===================================================================

-- Wrapped in closures (rather than storing the global functions directly)
-- so these resolve at call time, not at table-construction time here -
-- that way this doesn't depend on client/toggles.lua having already run
-- before this file does in the client_scripts load order.
local SELF_TOGGLES = {
    noclip = function() ToggleNoclip() end,
    revive = function() ToggleRevive() end,
    invisible = function() ToggleInvisible() end,
    godmode = function() ToggleGodmode() end,
    names = function() ToggleNames() end,
    blips = function() ToggleBlips() end,
    vehicleGodmode = function() ToggleVehicleGodmode() end,
    infiniteAmmo = function() ToggleInfiniteAmmo() end,
    cuff = function() ToggleCuff() end,
    coords = function() ToggleCoordsDisplay() end,
    vehicleInfo = function() ToggleVehicleInfoDisplay() end,
    laser = function() ToggleLaser() end,
}

-- config/actions.lua id for each SELF_TOGGLES key - these toggles used to
-- have no server-side permission check at all (purely client-local state,
-- gated only by whether the button was drawn), so this is what actually
-- enforces the tier an owner sets for each one now, not just the NUI
-- hiding the button.
local SELF_TOGGLE_ACTIONS = {
    noclip = 'self_noclip',
    revive = 'self_revive',
    invisible = 'self_invisible',
    godmode = 'self_godmode',
    names = 'self_names',
    blips = 'self_blips',
    vehicleGodmode = 'self_vehicleGodmode',
    infiniteAmmo = 'self_infiniteAmmo',
    cuff = 'self_cuff',
    coords = 'dev_coords',
    vehicleInfo = 'dev_vehicleInfo',
    laser = 'dev_laser',
}

RegisterNUICallback('toggleSelf', function(data, cb)
    local toggle = SELF_TOGGLES[data.action]
    local actionId = SELF_TOGGLE_ACTIONS[data.action]
    if toggle and actionId and lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, actionId) then
        -- A few of these (invisible/vehicleGodmode/infiniteAmmo in
        -- admin.lua, coords/vehicleInfo/laser in dev.lua) run their "on"
        -- state as a `while flag do ... Wait(0) end` loop directly in the
        -- closure body rather than inside their own CreateThread. That's
        -- fine for ox_lib's menu (which isolates each selection in its
        -- own thread) but would hang this NUI callback's cb() forever if
        -- called inline, so run it in a thread of our own instead.
        --
        -- CreateThread doesn't guarantee the flag flip (the closure's
        -- first line) has actually run by the time control returns here -
        -- a pushToggleState() call right after used to read the state
        -- from before the flip and stomp the tile back to the wrong
        -- value a moment after the click. The NUI side now flips its own
        -- tile optimistically on click instead (these toggles are pure
        -- client state and can't fail), so no push is needed here at
        -- all - the next real sync happens naturally when the menu is
        -- next opened (getToggleState).
        CreateThread(function() pcall(toggle) end)
    end
    -- Let the scheduler actually hand control to the thread just created
    -- above at least once before this callback returns - without this
    -- yield, cb('ok') could resolve before the toggle's flip line has
    -- run at all, and needed a second click to actually take effect (the
    -- tile itself still looked right immediately either way, since that's
    -- now driven by the optimistic click-time flip below, not this).
    Wait(0)
    cb('ok')
end)

RegisterNUICallback('setPedModel', function(data, cb)
    if data.model and data.model ~= '' and lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'self_setModel') then
        pcall(ApplyPedModel, data.model)
    end
    cb('ok')
end)

RegisterNUICallback('refreshPedModel', function(_, cb)
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'self_setModel') then
        pcall(RefreshPedModel)
    end
    cb('ok')
end)

RegisterNUICallback('getToggleState', function(_, cb)
    pushToggleState()
    cb('ok')
end)

-- ===================================================================
-- Vehicles
-- ===================================================================

RegisterNUICallback('getVehicles', function(_, cb)
    local coreVehicles = exports.qbx_core:GetVehiclesByName()
    local categories = {}
    local byCategory = {}

    for model, v in pairs(coreVehicles) do
        if not byCategory[v.category] then
            byCategory[v.category] = {}
            categories[#categories + 1] = v.category
        end
        byCategory[v.category][#byCategory[v.category] + 1] = { model = model, name = v.name }
    end

    table.sort(categories)
    for _, cat in ipairs(categories) do
        table.sort(byCategory[cat], function(a, b) return a.name < b.name end)
    end

    cb({ categories = categories, byCategory = byCategory })
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    local vehNetId = lib.callback.await('qbx_admin:server:spawnVehicle', false, data.model)
    if not vehNetId then cb('error') return end

    local veh
    local attempts = 0
    repeat
        veh = NetToVeh(vehNetId)
        attempts += 1
        Wait(100)
    until DoesEntityExist(veh) or attempts > 50

    if DoesEntityExist(veh) then
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehicleHasBeenOwnedByPlayer(veh, true)
        SetEntityAsMissionEntity(veh, true, false)
        SetVehicleIsStolen(veh, false)
        SetVehicleIsWanted(veh, false)
        SetVehicleEngineOn(veh, true, true, true)
        SetPedIntoVehicle(cache.ped, veh, -1)
        SetVehicleOnGroundProperly(veh)
        SetVehicleRadioEnabled(veh, true)
        SetVehRadioStation(veh, 'OFF')
    end

    close()
    cb('ok')
end)

-- fix/dv/admincar are qbx_core commands with their own restrictions
-- already, but the checks below are what actually make these three
-- individually configurable from this menu's own Admins tab, same as
-- everything else here - a tier change here wouldn't otherwise affect
-- qbx_core's separate, unrelated permission system for those commands.
RegisterNUICallback('fixVehicle', function(_, cb)
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'vehicle_fix') then
        ExecuteCommand('fix')
    end
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(_, cb)
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'vehicle_delete') then
        ExecuteCommand('dv')
    end
    cb('ok')
end)

RegisterNUICallback('adminCar', function(_, cb)
    -- /admincar itself is also gated server-side (vehicle_takeOwnership,
    -- server/commands.lua) - this check just avoids the round trip for
    -- someone who can already see the button doesn't apply to them.
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'vehicle_takeOwnership') then
        ExecuteCommand('admincar')
    end
    cb('ok')
end)

RegisterNUICallback('setPlate', function(data, cb)
    if not cache.vehicle then cb('error') return end
    if not lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'vehicle_setPlate') then cb('error') return end
    local plate = tostring(data.plate or ''):sub(1, 8)
    if plate == '' then cb('error') return end
    SetVehicleNumberPlateText(cache.vehicle, plate)
    cb('ok')
end)

-- ===================================================================
-- Server tools
-- ===================================================================

RegisterNUICallback('setWeather', function(data, cb)
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'server_weather') then
        TriggerServerEvent('qb-weathersync:server:setWeather', data.weather)
    end
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'server_time') then
        TriggerServerEvent('qb-weathersync:server:setTime', data.hour)
    end
    cb('ok')
end)

RegisterNUICallback('getRadioList', function(data, cb)
    lib.callback('qbx_admin:callback:getradiolist', false, function(players, frequency)
        cb({ players = players or {}, frequency = frequency })
    end, data.frequency)
end)

-- qbx_adminmenu's own "Pull Stash" used qb-inventory's legacy event
-- names ('inventory:server:OpenInventory' / 'inventory:client:SetCurrentStash'),
-- which ox_inventory (what this server actually runs) doesn't implement
-- at all — dead on arrival there. ox_inventory opens a stash by name
-- directly through its own client export instead.
RegisterNUICallback('pullStash', function(data, cb)
    if data.name and data.name ~= '' and lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'server_stash') then
        pcall(function() exports.ox_inventory:openInventory('stash', data.name) end)
        close()
    end
    cb('ok')
end)

-- ===================================================================
-- Dev tools
-- ===================================================================

-- Same function the /vec2 /vec3 /vec4 /heading commands use
-- (client/vectors.lua) - now a plain global in this same resource, so
-- the NUI callback can just call it directly instead of duplicating its
-- math. Those commands are also gated server-side (dev_copyCoords,
-- server/commands.lua) - this check is what gates the NUI button itself.
RegisterNUICallback('copyToClipboard', function(data, cb)
    if lib.callback.await('crazy_adminmenu:server:hasActionPerm', false, 'dev_copyCoords') then
        pcall(CopyToClipboard, data.kind)
    end
    cb('ok')
end)

-- ===================================================================
-- Reports
-- ===================================================================

RegisterNUICallback('getReports', function(_, cb)
    local reports = lib.callback.await('qbx_admin:server:getReports', false)
    cb(reports or {})
end)

RegisterNUICallback('replyReport', function(data, cb)
    if data.message and data.message ~= '' then
        TriggerServerEvent('qbx_admin:server:sendReply', data.report, data.message)
    end
    cb('ok')
end)

RegisterNUICallback('closeReport', function(data, cb)
    TriggerServerEvent('qbx_admin:server:deleteReport', data.report)
    cb('ok')
end)

-- ===================================================================
-- Ban logs
-- ===================================================================

RegisterNUICallback('getBans', function(_, cb)
    local bans = lib.callback.await('crazy_adminmenu:server:getBans', false)
    cb(bans or {})
end)

RegisterNUICallback('unban', function(data, cb)
    local ok = lib.callback.await('crazy_adminmenu:server:unban', false, data.id)
    cb(ok or false)
end)

-- ===================================================================
-- Owner-only staff (admin/mod/support) permission management
-- ===================================================================

RegisterNUICallback('isOwner', function(_, cb)
    local isOwner = lib.callback.await('crazy_adminmenu:server:isOwner', false)
    cb(isOwner or false)
end)

RegisterNUICallback('getStaff', function(_, cb)
    local staff = lib.callback.await('crazy_adminmenu:server:getStaff', false)
    cb(staff or {})
end)

-- data.target: a live player id (number, from the Players tab) or a
-- stored identifier (string, from the Admins tab). data.tier: 'support' |
-- 'mod' | 'admin' | 'none'.
RegisterNUICallback('setStaffTier', function(data, cb)
    local ok = lib.callback.await('crazy_adminmenu:server:setStaffTier', false, data.target, data.tier)
    cb(ok or false)
end)

-- ===================================================================
-- Owner-only action permissions (which tier each individual admin-menu
-- action requires - config/actions.lua)
-- ===================================================================

RegisterNUICallback('getActionPerms', function(_, cb)
    local list = lib.callback.await('crazy_adminmenu:server:getActionPerms', false)
    cb(list or {})
end)

RegisterNUICallback('setActionPerm', function(data, cb)
    local ok = lib.callback.await('crazy_adminmenu:server:setActionPerm', false, data.id, data.tier)
    cb(ok or false)
end)

-- Every non-owner tab/button check reads from this once per menu open
-- rather than calling hasActionPerm per element - see refreshOwnerStatus
-- in html/script.js.
RegisterNUICallback('getMyActionPerms', function(_, cb)
    local allowed = lib.callback.await('crazy_adminmenu:server:getMyActionPerms', false)
    cb(allowed or {})
end)

-- Per-player permission overrides ("Edit Permissions" box, from a player's
-- detail page in the Players tab or a staff row in the Admins tab) -
-- data.id is either that player's online source id (Players tab) or their
-- stored identifier as a string (Admins tab, may be offline) - see
-- server/permissions.lua's resolvePermissionTarget.
RegisterNUICallback('getPlayerPermissions', function(data, cb)
    local list = lib.callback.await('crazy_adminmenu:server:getPlayerPermissions', false, data.id)
    cb(list or {})
end)

RegisterNUICallback('setPlayerPermission', function(data, cb)
    local ok = lib.callback.await('crazy_adminmenu:server:setPlayerPermission', false, data.id, data.actionId, data.allowed)
    cb(ok or false)
end)

-- ===================================================================
-- Character lookup
-- ===================================================================

RegisterNUICallback('searchCharacters', function(data, cb)
    local results = lib.callback.await('crazy_adminmenu:server:searchCharacters', false, data.term)
    cb(results or {})
end)

RegisterNUICallback('getCharacterDetail', function(data, cb)
    local detail = lib.callback.await('crazy_adminmenu:server:getCharacterDetail', false, data.citizenid)
    cb(detail)
end)

-- Only meaningful when the looked-up character is currently online
-- (detail.onlineId, a real numeric server id) — same
-- exports.ox_inventory:openInventory('player', id) call the Players tab
-- already uses. There's no safe way to open a live-editable inventory
-- for an offline character (nothing has it loaded), which is why the
-- offline case is a read-only item summary built server-side instead
-- (see getCharacterDetail's `items` field).
RegisterNUICallback('openCharacterInventory', function(data, cb)
    if data.onlineId then
        pcall(function() exports.ox_inventory:openInventory('player', data.onlineId) end)
        close()
    end
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        close()
    end
end)
