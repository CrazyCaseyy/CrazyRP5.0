-- Backs the /fleetvehicle UI (client/fleetmenu.lua) - the actual fleet
-- data (vehicles, assignments) lives in qbx_garages/server/fleet.lua,
-- this just supplies the "who's currently online and police" list for
-- the officer picker, since that's qbx_police's own job data to know.

---@return { id: number, name: string, grade: string }[]
lib.callback.register('qbx_police:server:getOnlinePolice', function(source)
    local officers = {}
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local target = exports.qbx_core:GetPlayer(targetId)
        if target and target.PlayerData.job.name == 'police' then
            officers[#officers + 1] = {
                id = targetId,
                name = ('%s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname),
                grade = target.PlayerData.job.grade.name,
            }
        end
    end
    return officers
end)
