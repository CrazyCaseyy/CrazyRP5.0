-- Per-player, per-job reputation store. XP is earned by completing job
-- payouts (hooked into each job resource's own payout event) and maps to a
-- 10-level curve where each level requires more XP than the last (see
-- config.lua BaseXP/StepXP). Levels above 1 grant a payout bonus that job
-- scripts read via GetPayoutMultiplier before paying the player.

MySQL.query([[
    CREATE TABLE IF NOT EXISTS `player_reputation` (
        `citizenid` VARCHAR(50) NOT NULL,
        `job` VARCHAR(50) NOT NULL,
        `xp` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`citizenid`, `job`)
    )
]])

Reputation = {}

local PlayerReputation = {} -- [citizenid] = { [job] = xp }

-- Cumulative XP needed to REACH each level (level 1 starts at 0).
local xpThresholds = { [1] = 0 }
for level = 2, Config.Reputation.MaxLevel do
    local stepXP = Config.Reputation.BaseXP + (level - 2) * Config.Reputation.StepXP
    xpThresholds[level] = xpThresholds[level - 1] + stepXP
end

local maxXP = xpThresholds[Config.Reputation.MaxLevel]

local function getLevelFromXP(xp)
    local level = 1
    for l = 2, Config.Reputation.MaxLevel do
        if xp >= xpThresholds[l] then
            level = l
        else
            break
        end
    end
    return level
end

local function loadReputation(citizenid)
    if PlayerReputation[citizenid] then return end

    local rows = MySQL.query.await('SELECT `job`, `xp` FROM `player_reputation` WHERE `citizenid` = ?', { citizenid })
    local data = {}
    for _, row in ipairs(rows or {}) do
        data[row.job] = row.xp
    end
    PlayerReputation[citizenid] = data
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    loadReputation(Player.PlayerData.citizenid)
end)

AddEventHandler('playerDropped', function()
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        PlayerReputation[player.PlayerData.citizenid] = nil
    end
end)

---@param source number
---@param job string
---@return { xp: number, level: number, xpIntoLevel: number, xpForNextLevel: number, maxLevel: number }
function Reputation.GetState(source, job)
    if not Config.IncludedJobs[job] then
        return { xp = 0, level = 1, xpIntoLevel = 0, xpForNextLevel = xpThresholds[2], maxLevel = Config.Reputation.MaxLevel }
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return { xp = 0, level = 1, xpIntoLevel = 0, xpForNextLevel = xpThresholds[2], maxLevel = Config.Reputation.MaxLevel }
    end

    local citizenid = player.PlayerData.citizenid
    loadReputation(citizenid)

    local xp = PlayerReputation[citizenid][job] or 0
    local level = getLevelFromXP(xp)
    local levelFloor = xpThresholds[level]
    local levelCeil = xpThresholds[level + 1]

    return {
        xp = xp,
        level = level,
        xpIntoLevel = xp - levelFloor,
        xpForNextLevel = levelCeil and (levelCeil - levelFloor) or 0,
        maxLevel = Config.Reputation.MaxLevel,
    }
end

---@param source number
---@param job string
---@return number multiplier applied to a job payout, e.g. 1.32 for level 5
function Reputation.GetPayoutMultiplier(source, job)
    local state = Reputation.GetState(source, job)
    return 1 + ((state.level - 1) * Config.Reputation.PayoutBonusPerLevel)
end

---Adds reputation XP for completing `amount` job units (e.g. fares, drops,
---shifts) and persists it, notifying the player every time XP is gained
---(and again, separately, on a level-up).
---@param source number
---@param job string
---@param amount number
function Reputation.AddReputation(source, job, amount)
    if not Config.IncludedJobs[job] then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    loadReputation(citizenid)

    local before = PlayerReputation[citizenid][job] or 0
    local levelBefore = getLevelFromXP(before)

    local xpPerJob = Config.Reputation.XPPerJob[job] or 20
    local after = math.min(before + math.floor(amount * xpPerJob), maxXP)
    PlayerReputation[citizenid][job] = after

    MySQL.query('INSERT INTO `player_reputation` (`citizenid`, `job`, `xp`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `xp` = ?', { citizenid, job, after, after })

    local xpGained = after - before
    if xpGained > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            id = 'crazy_reputation_gain',
            title = 'Reputation',
            description = ('+%d reputation (%s)'):format(xpGained, player.PlayerData.job.label or job),
            showDuration = true,
            position = 'center-right',
            icon = 'star',
            iconColor = '#3ddc84',
        })
    end

    local levelAfter = getLevelFromXP(after)
    if levelAfter > levelBefore then
        TriggerClientEvent('ox_lib:notify', source, {
            id = 'crazy_reputation_levelup',
            title = 'Reputation Increased',
            description = ('You reached level %d reputation as a %s.'):format(levelAfter, player.PlayerData.job.label or job),
            showDuration = true,
            position = 'center-right',
            icon = 'arrow-up',
            iconColor = '#1573ed',
        })
    end

    -- Fired so other resources (e.g. crazy-dailytasks) can react to a
    -- completed job unit without this resource needing to know about them.
    TriggerEvent('crazy-reputation:server:jobCompleted', source, job, amount)
end

exports('AddReputation', Reputation.AddReputation)
exports('GetPayoutMultiplier', Reputation.GetPayoutMultiplier)
exports('GetReputation', Reputation.GetState)
