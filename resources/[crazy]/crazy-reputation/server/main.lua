-- Reputation UI - job list source, no reputation tracking yet (this is the
-- UI-only pass; real per-player rep values are a separate follow-up build).

---@return { name: string, label: string }[]
local function GetCivilianJobs()
    local jobs = exports.qbx_core:GetJobs()
    local list = {}

    for name, job in pairs(jobs) do
        if Config.IncludedJobs[name] then
            list[#list + 1] = { name = name, label = job.label or name }
        end
    end

    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

lib.callback.register('crazy-reputation:server:getCivilianJobs', function(_)
    return GetCivilianJobs()
end)

-- Same pattern qbx_idcard uses for its item (bridge/framework/qbox.lua):
-- exports.qbx_core:CreateUseableItem registers the item as usable, and the
-- callback just hands off to the client to actually open the NUI.
exports.qbx_core:CreateUseableItem(Config.ItemName, function(source)
    TriggerClientEvent('crazy-reputation:client:open', source)
end)
