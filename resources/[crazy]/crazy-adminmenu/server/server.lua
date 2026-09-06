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
-- Dashboard - player count + on-duty job counts
-- ===================================================================

-- The Players tab no longer calls this - its own getPlayers fetch already
-- carries an `onduty` flag per row now (server/admin.lua), so it tallies
-- job counts client-side from data it fetches anyway instead of triggering
-- a second callback that re-loops every online player. Only the Dashboard
-- still needs a server-side count, and it needs BOTH the total player
-- count and the on-duty breakdown - bundled into one callback so the
-- Dashboard costs one network round trip and one pass over
-- GetQBPlayers() (a cheap live-table reference, not a copy) instead of
-- two separate ones.
lib.callback.register('crazy_adminmenu:server:getDashboardStats', function(source)
    if not checkPerm(source, 'mod') then return { playerCount = 0, jobCounts = {} } end

    local counts = {}
    local playerCount = 0
    for _, v in pairs(exports.qbx_core:GetQBPlayers()) do
        playerCount += 1
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
    return { playerCount = playerCount, jobCounts = list }
end)

-- ===================================================================
-- Players tab - job/gang pickers (Edit Character Data)
-- ===================================================================

-- Grades are a 0-indexed table (grade 0 always exists), so the highest key
-- present is the max grade that job/gang actually has - can't use #grades
-- for this, Lua's length operator is undefined on a table starting at 0.
local function maxGradeOf(data)
    local max = 0
    for gradeId in pairs(data.grades) do
        if gradeId > max then max = gradeId end
    end
    return max
end

local function toGroupList(groups)
    local list = {}
    for name, data in pairs(groups) do
        list[#list + 1] = { name = name, label = data.label, maxGrade = maxGradeOf(data) }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

lib.callback.register('crazy_adminmenu:server:getJobsAndGangs', function(source)
    if not checkPerm(source, 'mod') then return { jobs = {}, gangs = {} } end
    return {
        jobs = toGroupList(exports.qbx_core:GetJobs()),
        gangs = toGroupList(exports.qbx_core:GetGangs()),
    }
end)

-- ===================================================================
-- Players tab - inventory viewer
-- ===================================================================

-- One row per occupied slot (not merged by item name) - same convention
-- getCharacterDetail below already uses for the offline inventory snapshot,
-- kept consistent rather than aggregating counts across stacks here.
lib.callback.register('crazy_adminmenu:server:getPlayerInventory', function(source, targetId)
    if not checkPerm(source, 'mod') then return {} end
    if not targetId then return {} end

    local slots = exports.ox_inventory:GetInventoryItems(targetId)
    if not slots then return {} end

    local itemDefs = exports.ox_inventory:Items()
    local items = {}
    for _, slot in pairs(slots) do
        if slot and slot.name then
            local def = itemDefs and itemDefs[slot.name]
            items[#items + 1] = {
                name = slot.name,
                label = def and def.label or slot.name,
                count = slot.count,
            }
        end
    end
    table.sort(items, function(a, b) return a.label < b.label end)
    return items
end)

-- ===================================================================
-- Dashboard - player count history (last 48h line chart)
-- ===================================================================

-- Self-installing table - no manual SQL import needed, same reasoning as
-- every other crazy- resource that owns its own data: CREATE TABLE IF NOT
-- EXISTS is idempotent, so this is safe to run on every resource start.
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS crazy_adminmenu_player_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_count INT NOT NULL,
            recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    local function sample()
        MySQL.insert('INSERT INTO crazy_adminmenu_player_history (player_count) VALUES (?)', { #GetPlayers() })
        -- Prune anything older than the 48h window this chart shows so the
        -- table doesn't grow forever - a little slack (49h) so a sample
        -- doesn't get pruned out from under the query below mid-request.
        MySQL.query('DELETE FROM crazy_adminmenu_player_history WHERE recorded_at < (NOW() - INTERVAL 49 HOUR)')
    end

    sample() -- once immediately so the chart isn't empty for the first
              -- interval after every resource restart
    while true do
        Wait(15 * 60 * 1000) -- 15 minutes - ~192 samples across 48h
        sample()
    end
end)

lib.callback.register('crazy_adminmenu:server:getPlayerHistory', function(source)
    if not checkPerm(source, 'mod') then return {} end
    return MySQL.query.await(
        'SELECT player_count, recorded_at FROM crazy_adminmenu_player_history WHERE recorded_at >= (NOW() - INTERVAL 48 HOUR) ORDER BY recorded_at ASC'
    ) or {}
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
