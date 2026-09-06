local isEscorted = false
local vehicleDict = 'veh@low@front_ps@idle_duck'
local vehicleAnim = 'sit'
local LastStandCuffedDict = 'dead'
local LastStandCuffedAnim = 'dead_f'

local function playUnescortedLastStandAnimation()
    if cache.vehicle then
        if not IsEntityPlayingAnim(cache.ped, vehicleDict, vehicleAnim, 3) then
            lib.playAnim(cache.ped, vehicleDict, vehicleAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        local playerData = QBX.PlayerData
        local metadata = playerData and playerData.metadata
        local isHandCuffed = metadata and metadata.ishandcuffed

        if isHandCuffed then
            if not IsEntityPlayingAnim(cache.ped, LastStandCuffedDict, LastStandCuffedAnim, 3) then
                lib.playAnim(cache.ped, LastStandCuffedDict, LastStandCuffedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
            end
        else
            -- Plain animFlags 1 (LOOPING) - same as this server's own "/e
            -- crawl" - so the ped is actually down on the ground in the
            -- crawl pose. A previous attempt used the UPPERBODY|SECONDARY
            -- combo scully_emotemenu's "Move" emotes use so GTA's own
            -- locomotion could drive movement, but that let normal
            -- (standing) locomotion take over the moment [W] was pressed -
            -- exactly the "still standing" bug this reverts. Movement is
            -- now handled manually instead (laststand.lua's
            -- updateCrawlMovement), independent of this anim entirely.
            if not IsEntityPlayingAnim(cache.ped, LastStandDict, LastStandAnim, 3) then
                lib.playAnim(cache.ped, LastStandDict, LastStandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
            end
        end
    end
end

---@param ped number
local function playEscortedLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict(vehicleDict, 5000)
        if IsEntityPlayingAnim(ped, vehicleDict, vehicleAnim, 3) then
            StopAnimTask(ped, vehicleDict, vehicleAnim, 3)
        end
        RemoveAnimDict(vehicleDict)
    else
        local dict = not QBX.PlayerData.metadata.ishandcuffed and LastStandDict or LastStandCuffedDict
        local anim = not QBX.PlayerData.metadata.ishandcuffed and LastStandAnim or LastStandCuffedAnim
        lib.requestAnimDict(dict, 5000)
        if IsEntityPlayingAnim(ped, dict, anim, 3) then
            StopAnimTask(ped, dict, anim, 3)
        end
        RemoveAnimDict(dict)
    end
end

function PlayLastStandAnimation()
    if isEscorted then
        playEscortedLastStandAnimation(cache.ped)
    else
        playUnescortedLastStandAnimation()
    end
end

---@param bool boolean
---TODO: this event name should be changed within qb-policejob to be generic
AddEventHandler('hospital:client:isEscorted', function(bool)
    isEscorted = bool
end)