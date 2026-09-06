-- Owner-only permission management, in two parts:
--   1. Staff tiers - who is support/mod/admin at all (grant/edit/revoke,
--      identifier-based ACE principals so it persists across restarts -
--      see the block below for why qbx_core's own AddPermission/
--      RemovePermission don't actually work for this).
--   2. Action permissions - which tier each individual admin-menu action
--      (config/actions.lua) requires, overridable per-action instead of
--      the old one-tier-per-whole-feature config/server.lua tables.
--
-- 'owner' itself is deliberately NOT one of the tiers grantable through
-- either system - it only comes from a manual
-- `add_principal identifier.xxx group.owner` in server.cfg (see
-- permissions.cfg's group.owner definition), the same way the first
-- admins were set up. Letting owners hand out more owners, or reassign an
-- owner-tier action to themselves, would make that tier meaningless.

local ACTIONS = require 'config.actions'

-- ===================================================================
-- Staff tiers
-- ===================================================================

-- Uses identifier-based ACE principals (identifier.license:xxx) instead
-- of qbx_core's own AddPermission/RemovePermission (@deprecated in
-- qbx_core/server/functions.lua, and keyed off 'player.<source>' - a
-- connection-slot number that changes every session, so grants made
-- through it don't actually persist at all). Identifier-based principals
-- are the same mechanism server.cfg's own hardcoded
-- `add_principal identifier.fivem:xxx group.admin` lines already use -
-- FXServer resolves these against a connecting player's identifiers
-- automatically, whether or not they're online at the moment the
-- principal is granted, and they stay in effect for the life of the
-- server process, which is why every row is replayed once below on
-- resource start (a real server restart, unlike ExecuteCommand-granted
-- principals, does forget them - this replay is what makes ours survive
-- it too, the same way server.cfg's own static lines do).

local VALID_TIERS = { support = true, mod = true, admin = true }
local ALL_TIERS = { 'support', 'mod', 'admin' }

---@param identifier string
local function findOnlinePlayerByIdentifier(identifier)
    for _, playerId in pairs(GetPlayers()) do
        if GetPlayerIdentifierByType(playerId, 'license') == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

-- Owners never go through setStaffTier (VALID_TIERS below deliberately
-- excludes 'owner'), so they'd otherwise never appear in
-- crazy_adminmenu_staff or the Admins tab's Staff list at all - server.cfg
-- is the only thing that actually grants that tier, and there's no way to
-- enumerate its `add_principal ... group.owner` lines from Lua at
-- runtime. This is the workaround: record a read-only row for anyone seen
-- online with the owner ACE, the first time they're seen (on connect, and
-- once for whoever's already online when this resource itself starts) -
-- after that they show up in Staff like everyone else, whether they're
-- currently online or not.
local function recordOwnerIfApplicable(playerId)
    if not IsPlayerAceAllowed(playerId, 'owner') then return end

    local identifier = GetPlayerIdentifierByType(playerId, 'license')
    if not identifier then return end

    local player = exports.qbx_core:GetPlayer(playerId)
    local name = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' | (' .. GetPlayerName(playerId) .. ')') or GetPlayerName(playerId)

    MySQL.query.await([[
        INSERT INTO crazy_adminmenu_staff (identifier, name, tier, granted_by)
        VALUES (?, ?, 'owner', 'server.cfg')
        ON DUPLICATE KEY UPDATE name = VALUES(name)
    ]], { identifier, name })
end

AddEventHandler('QBCore:Server:OnPlayerLoaded', function(playerId)
    recordOwnerIfApplicable(playerId)
end)

-- Gate for the two staff-tier endpoints below only (getStaff, setStaffTier)
-- - a real owner always passes, and so does anyone specifically holding the
-- 'admin_grantStaff' action (config/actions.lua, defaults to the 'owner'
-- tier so it's off for every staff rank until an owner explicitly hands it
-- out via the Admins tab's Action Permissions list or a per-player
-- override). Deliberately NOT used for getActionPerms/setActionPerm or the
-- per-player override endpoints further down - those stay owner-only, this
-- only delegates the ability to grant/edit OTHER players' staff tier.
-- hasActionPerm is defined further down this same file, but as a global
-- function that's only actually looked up when this is called (long after
-- the whole file has finished running once), so the forward reference here
-- is safe.
---@param source number
---@return boolean
local function checkStaffManage(source)
    if not (IsPlayerAceAllowed(source, 'owner') or hasActionPerm(source, 'admin_grantStaff')) then
        exports.qbx_core:Notify(source, "You don't have permission to do this", 'error')
        return false
    end
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return false
    end
    return true
end

lib.callback.register('crazy_adminmenu:server:getStaff', function(source)
    if not checkStaffManage(source) then return {} end

    local rows = MySQL.query.await('SELECT identifier, name, tier, granted_by, granted_at FROM crazy_adminmenu_staff ORDER BY FIELD(tier, \'owner\', \'admin\', \'mod\', \'support\'), name') or {}
    for _, row in pairs(rows) do
        row.onlineId = findOnlinePlayerByIdentifier(row.identifier)
    end
    return rows
end)

-- target: either a number (an online player's source id, from the Players
-- tab) or a string (a stored identifier, from the Admins tab - may or may
-- not currently be online). tier: 'support' | 'mod' | 'admin' | 'none'
-- (revoke).
lib.callback.register('crazy_adminmenu:server:setStaffTier', function(source, target, tier)
    if not checkStaffManage(source) then return false end
    if tier ~= 'none' and not VALID_TIERS[tier] then return false end

    local identifier, name
    if type(target) == 'number' then
        identifier = GetPlayerIdentifierByType(target, 'license')
        local player = exports.qbx_core:GetPlayer(target)
        name = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' | (' .. GetPlayerName(target) .. ')') or GetPlayerName(target)
    else
        identifier = target
        local onlineId = findOnlinePlayerByIdentifier(identifier)
        if onlineId then
            local player = exports.qbx_core:GetPlayer(onlineId)
            name = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' | (' .. GetPlayerName(onlineId) .. ')') or GetPlayerName(onlineId)
        end
    end
    if not identifier then
        exports.qbx_core:Notify(source, 'Could not find that player.', 'error')
        return false
    end

    -- Backstop for a delegated (non-owner) grantor targeting an owner's row
    -- directly - the Staff list's tier control is already hidden entirely
    -- for owner rows (html/script.js's renderStaff), this just makes sure
    -- nothing can reach it a different way either. Owner tier itself is
    -- untouched either way (it's not in ALL_TIERS below), this only stops
    -- the DISPLAY row from getting overwritten to a lesser tier.
    local existingTier = MySQL.scalar.await('SELECT tier FROM crazy_adminmenu_staff WHERE identifier = ?', { identifier })
    if existingTier == 'owner' then
        exports.qbx_core:Notify(source, 'Owner tier can only be changed in server.cfg.', 'error')
        return false
    end

    -- Always clear every grantable tier first so switching tiers (e.g.
    -- mod -> admin) doesn't stack principals - owner is never touched
    -- here, see the header comment.
    for _, existingTierToClear in ipairs(ALL_TIERS) do
        lib.removePrincipal('identifier.' .. identifier, 'group.' .. existingTierToClear)
    end

    if tier == 'none' then
        MySQL.query.await('DELETE FROM crazy_adminmenu_staff WHERE identifier = ?', { identifier })
        exports.qbx_core:Notify(source, 'Staff permissions revoked.', 'success')
        return true
    end

    lib.addPrincipal('identifier.' .. identifier, 'group.' .. tier)
    MySQL.query.await([[
        INSERT INTO crazy_adminmenu_staff (identifier, name, tier, granted_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE tier = VALUES(tier), granted_by = VALUES(granted_by), name = COALESCE(VALUES(name), name)
    ]], { identifier, name, tier, GetPlayerName(source) })

    exports.qbx_core:Notify(source, ('Set to %s.'):format(tier), 'success')
    return true
end)

lib.callback.register('crazy_adminmenu:server:isOwner', function(source)
    return IsPlayerAceAllowed(source, 'owner')
end)

-- ===================================================================
-- Action permissions
-- ===================================================================

local ACTION_BY_ID = {}
for _, action in ipairs(ACTIONS) do
    ACTION_BY_ID[action.id] = action
end

-- In-memory merged view (defaults from config/actions.lua, overridden by
-- whatever's in the DB) - every hasActionPerm() check reads this table
-- directly rather than hitting the database per-call.
local ACTION_TIERS = {}
for _, action in ipairs(ACTIONS) do
    ACTION_TIERS[action.id] = action.default
end

-- Per-player overrides (identifier -> actionId -> true/false) on top of
-- the tier system above - set from a specific player's "Edit Permissions"
-- box (Players tab), for the rare case an owner wants to grant or deny one
-- specific action for one specific player regardless of their tier,
-- without having to invent a whole new tier for it. Checked before the
-- tier fallback in hasActionPerm, so an explicit override always wins.
local PLAYER_OVERRIDES = {}

-- Shared by every file in this resource that used to check
-- config/server.lua's old commandPerms/eventPerms tables - falls back to
-- 'admin' for any id that's somehow missing from the registry, erring
-- toward more restrictive rather than silently open.
function hasActionPerm(source, actionId)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    local overrides = identifier and PLAYER_OVERRIDES[identifier]
    if overrides and overrides[actionId] ~= nil then
        return overrides[actionId]
    end

    local tier = ACTION_TIERS[actionId] or 'admin'
    return IsPlayerAceAllowed(source, tier)
end

-- Same check, but for the client to ask about its own currently-connected
-- player without needing a distinct callback per action - used to hide UI
-- for actions the viewer can't use rather than just letting them click it
-- and get rejected server-side.
lib.callback.register('crazy_adminmenu:server:getMyActionPerms', function(source)
    local allowed = {}
    for actionId, tier in pairs(ACTION_TIERS) do
        if IsPlayerAceAllowed(source, tier) then
            allowed[#allowed + 1] = actionId
        end
    end
    return allowed
end)

-- Single-action version of the above, for spots that gate one specific
-- thing right before doing it (client/client.lua's toggleSelf) rather
-- than checking membership in a bulk list fetched once - the purely
-- client-local Self Tools/Dev Tools toggles (noclip, godmode, coords
-- overlay, etc.) had no server-side enforcement at all before this, only
-- the NUI button existing; this is what actually gates them now, not just
-- hides the button.
lib.callback.register('crazy_adminmenu:server:hasActionPerm', function(source, actionId)
    return hasActionPerm(source, actionId)
end)

lib.callback.register('crazy_adminmenu:server:getActionPerms', function(source)
    if not checkPerm(source, 'owner') then return {} end

    local list = {}
    for _, action in ipairs(ACTIONS) do
        list[#list + 1] = {
            id = action.id,
            category = action.category,
            label = action.label,
            tier = ACTION_TIERS[action.id],
        }
    end
    table.sort(list, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        return a.label < b.label
    end)
    return list
end)

lib.callback.register('crazy_adminmenu:server:setActionPerm', function(source, actionId, tier)
    if not checkPerm(source, 'owner') then return false end
    if not ACTION_BY_ID[actionId] then return false end
    if not VALID_TIERS[tier] then return false end -- 'owner' excluded here too, same reasoning as staff tiers above

    ACTION_TIERS[actionId] = tier
    MySQL.query.await([[
        INSERT INTO crazy_adminmenu_action_perms (action_id, tier, updated_by)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE tier = VALUES(tier), updated_by = VALUES(updated_by)
    ]], { actionId, tier, GetPlayerName(source) })

    exports.qbx_core:Notify(source, ('%s set to %s.'):format(ACTION_BY_ID[actionId].label, tier), 'success')
    return true
end)

-- ===================================================================
-- Per-player permission overrides ("Edit Permissions" box, Players tab
-- and Admins tab)
-- ===================================================================

-- target: either a number (an online player's source id, from the Players
-- tab) or a string (a stored identifier, from the Admins tab Staff list -
-- may or may not currently be online) - same duality as setStaffTier above.
---@param target number|string
---@return string? identifier, number? onlineId
local function resolvePermissionTarget(target)
    if type(target) == 'number' then
        local identifier = GetPlayerIdentifierByType(target, 'license')
        if not identifier then return nil end
        return identifier, target
    end
    return target, findOnlinePlayerByIdentifier(target)
end

-- Whether `identifier` currently has `tier` - checked live against the
-- player's ACE principal when they're online, or against the bare
-- identifier principal via IsPrincipalAceAllowed when they're not (this is
-- what makes editing an offline admin's overrides from the Admins tab show
-- accurate "currently allowed" values instead of just guessing).
---@param identifier string
---@param onlineId number?
---@param tier string
local function identifierHasTier(identifier, onlineId, tier)
    if onlineId then
        return IsPlayerAceAllowed(onlineId, tier)
    end
    return IsPrincipalAceAllowed('identifier.' .. identifier, tier)
end

lib.callback.register('crazy_adminmenu:server:getPlayerPermissions', function(source, target)
    if not checkPerm(source, 'owner') then return {} end

    local identifier, onlineId = resolvePermissionTarget(target)
    if not identifier then return {} end

    local overrides = PLAYER_OVERRIDES[identifier] or {}

    local list = {}
    for _, action in ipairs(ACTIONS) do
        local override = overrides[action.id]
        list[#list + 1] = {
            id = action.id,
            category = action.category,
            label = action.label,
            -- What they can actually do right now - the override if one
            -- exists for this action, otherwise their tier's default,
            -- exactly what hasActionPerm itself would return.
            allowed = override ~= nil and override or identifierHasTier(identifier, onlineId, ACTION_TIERS[action.id]),
            isOverride = override ~= nil,
        }
    end
    table.sort(list, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        return a.label < b.label
    end)
    return list
end)

-- allowed: true (explicitly grant) or false (explicitly deny) - always
-- writes an explicit override, there's no "reset to tier default" option
-- here (unchecking denies rather than clearing the override) to keep the
-- checkbox behavior simple and predictable.
lib.callback.register('crazy_adminmenu:server:setPlayerPermission', function(source, target, actionId, allowed)
    if not checkPerm(source, 'owner') then return false end
    if not ACTION_BY_ID[actionId] then return false end

    local identifier = resolvePermissionTarget(target)
    if not identifier then
        exports.qbx_core:Notify(source, 'Could not find that player.', 'error')
        return false
    end

    PLAYER_OVERRIDES[identifier] = PLAYER_OVERRIDES[identifier] or {}
    PLAYER_OVERRIDES[identifier][actionId] = allowed and true or false

    MySQL.query.await([[
        INSERT INTO crazy_adminmenu_player_action_perms (identifier, action_id, allowed, updated_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE allowed = VALUES(allowed), updated_by = VALUES(updated_by)
    ]], { identifier, actionId, allowed and 1 or 0, GetPlayerName(source) })

    return true
end)

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS crazy_adminmenu_staff (
            identifier VARCHAR(60) NOT NULL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            tier VARCHAR(20) NOT NULL,
            granted_by VARCHAR(100) NOT NULL,
            granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS crazy_adminmenu_action_perms (
            action_id VARCHAR(60) NOT NULL PRIMARY KEY,
            tier VARCHAR(20) NOT NULL,
            updated_by VARCHAR(100) NOT NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS crazy_adminmenu_player_action_perms (
            identifier VARCHAR(60) NOT NULL,
            action_id VARCHAR(60) NOT NULL,
            allowed TINYINT(1) NOT NULL,
            updated_by VARCHAR(100) NOT NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (identifier, action_id)
        )
    ]])

    local staffRows = MySQL.query.await('SELECT identifier, tier FROM crazy_adminmenu_staff') or {}
    for _, row in pairs(staffRows) do
        -- 'owner' rows are purely a cached display record (see
        -- recordOwnerIfApplicable above) - never re-granted here, unlike
        -- support/mod/admin. server.cfg has to stay the only thing that
        -- actually grants owner, or removing someone's server.cfg line
        -- wouldn't actually revoke it as long as this row still existed.
        if row.tier ~= 'owner' then
            lib.addPrincipal('identifier.' .. row.identifier, 'group.' .. row.tier)
        end
    end

    -- Catches anyone already connected with the owner ACE if this
    -- resource itself starts/restarts mid-session - recordOwnerIfApplicable
    -- is otherwise only called from the OnPlayerLoaded hook above, which
    -- won't fire again for someone who loaded in before this resource did.
    for _, playerId in pairs(GetPlayers()) do
        recordOwnerIfApplicable(tonumber(playerId))
    end

    local actionRows = MySQL.query.await('SELECT action_id, tier FROM crazy_adminmenu_action_perms') or {}
    for _, row in pairs(actionRows) do
        -- Ignore overrides for action ids that no longer exist (e.g. this
        -- file's config/actions.lua dropped one since the override was
        -- saved) rather than letting a stale id leak into ACTION_TIERS.
        if ACTION_BY_ID[row.action_id] then
            ACTION_TIERS[row.action_id] = row.tier
        end
    end

    local playerOverrideRows = MySQL.query.await('SELECT identifier, action_id, allowed FROM crazy_adminmenu_player_action_perms') or {}
    for _, row in pairs(playerOverrideRows) do
        if ACTION_BY_ID[row.action_id] then
            PLAYER_OVERRIDES[row.identifier] = PLAYER_OVERRIDES[row.identifier] or {}
            PLAYER_OVERRIDES[row.identifier][row.action_id] = row.allowed == 1
        end
    end
end)
