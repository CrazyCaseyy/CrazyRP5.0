-- NUI dashboard front-end for qbx_adminmenu. Every action below triggers
-- the exact same server events/callbacks qbx_adminmenu's own ox_lib menu
-- already used (see [qbx]/qbx_adminmenu/server/main.lua) — permission
-- checks (IsPlayerAceAllowed against config.eventPerms/commandPerms) and
-- the /optin gate happen there, unchanged. This resource only replaces
-- the front-end; qbx_adminmenu's server scripts must still be running.
--
-- The handful of purely-client-local toggles qbx_adminmenu's admin.lua
-- and dev.lua own (noclip, godmode, invisible, vehicle godmode, infinite
-- ammo, cuff, ped model, coords/vehicle-info overlays) are reached
-- through exports added to those two files rather than being
-- reimplemented here — see the 'exports(...)' calls added to
-- [qbx]/qbx_adminmenu/client/admin.lua and client/dev.lua.
--
-- Ban logs and character lookup are the two things qbx_adminmenu never
-- had server logic for, so those NUI callbacks talk to this resource's
-- own server/server.lua instead (crazy_adminmenu:server:* events).

local isOpen = false

local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function pushToggleState()
    local ok, adminState = pcall(function() return exports.qbx_adminmenu:GetAdminToggleState() end)
    local ok2, devState = pcall(function() return exports.qbx_adminmenu:GetDevToggleState() end)
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

-- Matches the index order qbx_adminmenu's generalOptions table uses
-- (server/main.lua) — kill/revive/freeze/goto/bring/sit/routing.
local GENERAL_ACTIONS = {
    kill = 1, revive = 2, freeze = 3, goto_ = 4, bring = 5, sit = 6, routing = 7,
}

RegisterNUICallback('playerGeneral', function(data, cb)
    local index = GENERAL_ACTIONS[data.action]
    if not index then cb('error') return end
    TriggerServerEvent('qbx_admin:server:playerOptionsGeneral', index, { id = data.id }, data.input)
    cb('ok')
end)

-- Matches qbx_adminmenu's administrationOptions index order: kick/ban/perm.
local ADMIN_ACTIONS = { kick = 1, ban = 2, perm = 3 }

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

RegisterNUICallback('giveWeapons', function(data, cb)
    TriggerServerEvent('qbx_admin:server:giveAllWeapons', data.weaponType, data.id)
    cb('ok')
end)

RegisterNUICallback('clothingMenu', function(data, cb)
    local ok = lib.callback.await('qbx_admin:server:clothingMenu', false, data.id)
    cb(ok or false)
end)

RegisterNUICallback('openInventory', function(data, cb)
    pcall(function() exports.ox_inventory:openInventory('player', data.id) end)
    close()
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    if data.item and data.item ~= '' and tonumber(data.amount) and tonumber(data.amount) > 0 then
        ExecuteCommand(('giveitem %s %s %s'):format(data.id, data.item, data.amount))
    end
    cb('ok')
end)

RegisterNUICallback('mutePlayer', function(data, cb)
    pcall(function() exports['pma-voice']:toggleMutePlayer(data.id) end)
    cb('ok')
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

local SELF_TOGGLES = {
    noclip = function() exports.qbx_adminmenu:ToggleNoclip() end,
    revive = function() exports.qbx_adminmenu:ToggleRevive() end,
    invisible = function() exports.qbx_adminmenu:ToggleInvisible() end,
    godmode = function() exports.qbx_adminmenu:ToggleGodmode() end,
    names = function() exports.qbx_adminmenu:ToggleNames() end,
    blips = function() exports.qbx_adminmenu:ToggleBlips() end,
    vehicleGodmode = function() exports.qbx_adminmenu:ToggleVehicleGodmode() end,
    infiniteAmmo = function() exports.qbx_adminmenu:ToggleInfiniteAmmo() end,
    cuff = function() exports.qbx_adminmenu:ToggleCuff() end,
    coords = function() exports.qbx_adminmenu:ToggleCoordsDisplay() end,
    vehicleInfo = function() exports.qbx_adminmenu:ToggleVehicleInfoDisplay() end,
    laser = function() exports.qbx_adminmenu:ToggleLaser() end,
}

RegisterNUICallback('toggleSelf', function(data, cb)
    local toggle = SELF_TOGGLES[data.action]
    if toggle then
        -- A few of these (invisible/vehicleGodmode/infiniteAmmo in
        -- admin.lua, coords/vehicleInfo in dev.lua) run their "on" state
        -- as a `while flag do ... Wait(0) end` loop directly in the
        -- closure body rather than inside their own CreateThread. That's
        -- fine for ox_lib's menu (which isolates each selection in its
        -- own thread) but would hang this NUI callback's cb() forever if
        -- called inline, so run it in a thread of our own instead. The
        -- toggle's state flag flips before the loop/first Wait, so it's
        -- already updated by the time pushToggleState() runs below.
        CreateThread(function() pcall(toggle) end)
    end
    Wait(0)
    pushToggleState()
    cb('ok')
end)

RegisterNUICallback('giveWeaponType', function(data, cb)
    pcall(function() exports.qbx_adminmenu:GiveWeaponType(data.weaponType) end)
    cb('ok')
end)

RegisterNUICallback('setPedModel', function(data, cb)
    if data.model and data.model ~= '' then
        pcall(function() exports.qbx_adminmenu:ApplyPedModel(data.model) end)
    end
    cb('ok')
end)

RegisterNUICallback('refreshPedModel', function(_, cb)
    pcall(function() exports.qbx_adminmenu:RefreshPedModel() end)
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

RegisterNUICallback('fixVehicle', function(_, cb)
    ExecuteCommand('fix')
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(_, cb)
    ExecuteCommand('dv')
    cb('ok')
end)

RegisterNUICallback('adminCar', function(_, cb)
    ExecuteCommand('admincar')
    cb('ok')
end)

RegisterNUICallback('setPlate', function(data, cb)
    if not cache.vehicle then cb('error') return end
    local plate = tostring(data.plate or ''):sub(1, 8)
    if plate == '' then cb('error') return end
    SetVehicleNumberPlateText(cache.vehicle, plate)
    cb('ok')
end)

-- ===================================================================
-- Server tools
-- ===================================================================

RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('qb-weathersync:server:setWeather', data.weather)
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('qb-weathersync:server:setTime', data.hour)
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
    if data.name and data.name ~= '' then
        pcall(function() exports.ox_inventory:openInventory('stash', data.name) end)
        close()
    end
    cb('ok')
end)

-- ===================================================================
-- Dev tools
-- ===================================================================

-- Same math qbx_adminmenu's client/vectors.lua uses for its /vec2 /vec3
-- /vec4 /heading commands — that function is resource-local (a bare
-- global only qbx_adminmenu's own scripts can see), so reimplemented
-- here directly rather than via a cross-resource call.
RegisterNUICallback('copyToClipboard', function(data, cb)
    local coords = GetEntityCoords(cache.ped)
    local x, y, z = qbx.math.round(coords.x, 2), qbx.math.round(coords.y, 2), qbx.math.round(coords.z, 2)
    local h = qbx.math.round(GetEntityHeading(cache.ped), 2)

    local value
    if data.kind == 'coords2' then
        value = ('vec2(%s, %s)'):format(x, y)
    elseif data.kind == 'coords3' then
        value = ('vec3(%s, %s, %s)'):format(x, y, z - 1.0)
    elseif data.kind == 'coords4' then
        value = ('vec4(%s, %s, %s, %s)'):format(x, y, z - 1.0, h)
    elseif data.kind == 'heading' then
        value = tostring(h)
    end

    if value then
        lib.setClipboard(value)
        exports.qbx_core:Notify('Copied to clipboard', 'success')
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
