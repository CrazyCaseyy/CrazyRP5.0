-- Ban log lookups, character (players table) search, and on-duty job
-- counts — things the old qbx_adminmenu resource never had server logic
-- for (it only had an ox_lib menu with no ban/character-lookup features
-- at all), so this talks to the database directly instead of routing
-- through server/admin.lua's qbx_admin:server:* events. Permission tiers
-- ('mod'/'admin') match the bare-ACE-object convention every check in
-- server/admin.lua and server/commands.lua uses (see config/server.lua's
-- eventPerms/commandPerms) — already granted correctly to group.admin
-- via permissions.cfg.

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
-- Players tab - on-duty job counts
-- ===================================================================

-- qbx_adminmenu's own getPlayers callback (server/main.lua) already
-- formats job as a flattened "Label | Grade" string for its own list row,
-- so counts are done here instead of trying to parse that back apart -
-- this loops the same qbx_core player pool directly.
lib.callback.register('crazy_adminmenu:server:getJobCounts', function(source)
    if not checkPerm(source, 'mod') then return {} end

    local counts = {}
    for _, v in pairs(exports.qbx_core:GetQBPlayers()) do
        local job = v.PlayerData.job
        if job and job.onduty and job.name ~= 'unemployed' then
            local entry = counts[job.name]
            if not entry then
                entry = { name = job.name, label = job.label, count = 0 }
                counts[job.name] = entry
            end
            entry.count += 1
        end
    end

    local list = {}
    for _, entry in pairs(counts) do
        list[#list + 1] = entry
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.label < b.label
    end)
    return list
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
