-- Reputation UI - job list source, with each job's real level/XP progress
-- attached from the reputation store (server/reputation.lua).

---@param source number
---@return { name: string, label: string, level: number, xp: number, xpIntoLevel: number, xpForNextLevel: number, maxLevel: number }[]
local function GetCivilianJobs(source)
    local jobs = exports.qbx_core:GetJobs()
    local list = {}

    for name, job in pairs(jobs) do
        if Config.IncludedJobs[name] then
            local state = Reputation.GetState(source, name)
            list[#list + 1] = {
                name = name,
                label = job.label or name,
                level = state.level,
                xp = state.xp,
                xpIntoLevel = state.xpIntoLevel,
                xpForNextLevel = state.xpForNextLevel,
                maxLevel = state.maxLevel,
            }
        end
    end

    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

lib.callback.register('crazy-reputation:server:getCivilianJobs', function(source)
    return GetCivilianJobs(source)
end)

-- Same pattern qbx_idcard uses for its item (bridge/framework/qbox.lua):
-- exports.qbx_core:CreateUseableItem registers the item as usable, and the
-- callback just hands off to the client to actually open the NUI.
exports.qbx_core:CreateUseableItem(Config.ItemName, function(source)
    TriggerClientEvent('crazy-reputation:client:open', source)
end)
