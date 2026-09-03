-- Daily task board: 3 random civilian-job tasks per player, reset every
-- time this resource (or the whole server) restarts. Progress is driven by
-- crazy-reputation's jobCompleted event (fired once per completed job unit
-- - fare, drop, shift), rewarding Config.RewardItem on completion.

MySQL.query([[
    CREATE TABLE IF NOT EXISTS `player_daily_tasks` (
        `citizenid` VARCHAR(50) NOT NULL,
        `date` VARCHAR(10) NOT NULL,
        `tasks` LONGTEXT NOT NULL,
        PRIMARY KEY (`citizenid`)
    )
]])

local PlayerTasks = {} -- [citizenid] = { date = ServerEpoch, tasks = { { job, label, target, progress, completed } } }

-- Set once when this resource starts. Tasks reset whenever this changes,
-- i.e. on every server/resource restart - not just once per calendar day.
local ServerEpoch = tostring(os.time())

local jobKeys = {}
for job in pairs(Config.JobTargets) do
    jobKeys[#jobKeys + 1] = job
end

local function generateTasks()
    local pool = {}
    for i, job in ipairs(jobKeys) do pool[i] = job end

    -- Fisher-Yates shuffle, then take the first TaskCount.
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local tasks = {}
    for i = 1, math.min(Config.TaskCount, #pool) do
        local job = pool[i]
        local cfg = Config.JobTargets[job]
        tasks[i] = {
            job = job,
            label = cfg.label,
            target = math.random(cfg.min, cfg.max),
            progress = 0,
            completed = false,
        }
    end

    return tasks
end

local function saveTasks(citizenid)
    local state = PlayerTasks[citizenid]
    if not state then return end

    MySQL.query('INSERT INTO `player_daily_tasks` (`citizenid`, `date`, `tasks`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `date` = ?, `tasks` = ?',
        { citizenid, state.date, json.encode(state.tasks), state.date, json.encode(state.tasks) })
end

local function loadTasks(citizenid)
    if PlayerTasks[citizenid] and PlayerTasks[citizenid].date == ServerEpoch then return end

    local row = MySQL.single.await('SELECT `date`, `tasks` FROM `player_daily_tasks` WHERE `citizenid` = ?', { citizenid })

    if row and row.date == ServerEpoch then
        PlayerTasks[citizenid] = { date = row.date, tasks = json.decode(row.tasks) }
    else
        PlayerTasks[citizenid] = { date = ServerEpoch, tasks = generateTasks() }
        saveTasks(citizenid)
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    loadTasks(Player.PlayerData.citizenid)
end)

AddEventHandler('playerDropped', function()
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        PlayerTasks[player.PlayerData.citizenid] = nil
    end
end)

lib.callback.register('crazy-dailytasks:server:getTasks', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    loadTasks(player.PlayerData.citizenid)
    return PlayerTasks[player.PlayerData.citizenid].tasks
end)

AddEventHandler('crazy-reputation:server:jobCompleted', function(source, job, amount)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    loadTasks(citizenid)

    local state = PlayerTasks[citizenid]
    local changed = false

    for _, task in ipairs(state.tasks) do
        if task.job == job and not task.completed then
            task.progress = math.min(task.progress + amount, task.target)
            changed = true

            if task.progress >= task.target then
                task.completed = true

                exports.ox_inventory:AddItem(source, Config.RewardItem, 1)
                TriggerClientEvent('ox_lib:notify', source, {
                    id = 'crazy_dailytasks_complete',
                    title = 'Daily Task Complete',
                    description = ('%s task finished - a Case has been added to your inventory.'):format(task.label),
                    showDuration = true,
                    position = 'center-right',
                    icon = 'briefcase',
                    iconColor = '#1573ed',
                })
            end
        end
    end

    if changed then
        saveTasks(citizenid)
        TriggerClientEvent('crazy-dailytasks:client:refreshTasks', source, state.tasks)
    end
end)
