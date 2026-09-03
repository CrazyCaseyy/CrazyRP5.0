-- Ban log lookups and character (players table) search — the two things
-- qbx_adminmenu itself never had server logic for, so unlike client.lua
-- (which is a pure front-end reusing qbx_adminmenu's own events), this
-- talks to the database directly. Permission tiers ('mod'/'admin') match
-- the bare-ACE-object convention every other qbx_adminmenu check in this
-- server uses (see [qbx]/qbx_adminmenu/config/server.lua eventPerms) —
-- already granted correctly to group.admin via permissions.cfg.

local function checkPerm(source, tier)
    if not IsPlayerAceAllowed(source, tier) then
        exports.qbx_core:Notify(source, "You don't have permission to do this", 'error')
        return false
    end
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return false
    end
    return true
end

-- ===================================================================
-- Ban logs
-- ===================================================================

lib.callback.register('crazy_adminmenu:server:getBans', function(source)
    if not checkPerm(source, 'admin') then return {} end
    return MySQL.query.await('SELECT id, name, license, discord, reason, expire, bannedby FROM bans ORDER BY id DESC LIMIT 200') or {}
end)

lib.callback.register('crazy_adminmenu:server:unban', function(source, id)
    if not checkPerm(source, 'admin') then return false end
    if not id then return false end
    MySQL.query.await('DELETE FROM bans WHERE id = ?', { id })
    return true
end)

-- ===================================================================
-- Character lookup
-- ===================================================================

lib.callback.register('crazy_adminmenu:server:searchCharacters', function(source, term)
    if not checkPerm(source, 'mod') then return {} end
    term = tostring(term or ''):gsub('%s+', '')
    if term == '' then return {} end

    local like = '%' .. term .. '%'
    return MySQL.query.await(
        'SELECT citizenid, name FROM players WHERE name LIKE ? OR citizenid LIKE ? ORDER BY last_logged_out DESC LIMIT 50',
        { like, like }
    ) or {}
end)

lib.callback.register('crazy_adminmenu:server:getCharacterDetail', function(source, citizenid)
    if not checkPerm(source, 'mod') then return end
    if not citizenid then return end

    local player = exports.qbx_core:GetOfflinePlayer(citizenid)
    if not player then return end

    local onlinePlayer = exports.qbx_core:GetPlayerByCitizenId(citizenid)

    local invRow = MySQL.single.await('SELECT inventory FROM players WHERE citizenid = ?', { citizenid })
    local items = {}
    if invRow and invRow.inventory then
        local ok, decoded = pcall(json.decode, invRow.inventory)
        if ok and type(decoded) == 'table' then
            local itemDefs = exports.ox_inventory:Items()
            for i = 1, #decoded do
                local slot = decoded[i]
                local def = itemDefs and itemDefs[slot.name]
                items[#items + 1] = {
                    name = slot.name,
                    label = def and def.label or slot.name,
                    count = slot.count,
                }
            end
        end
    end

    return {
        citizenid = player.citizenid,
        name = player.name,
        license = player.license,
        charinfo = player.charinfo,
        money = player.money,
        job = player.job,
        gang = player.gang,
        lastLoggedOut = player.lastLoggedOut,
        online = onlinePlayer ~= nil,
        onlineId = onlinePlayer and onlinePlayer.PlayerData.source or nil,
        items = items,
    }
end)
