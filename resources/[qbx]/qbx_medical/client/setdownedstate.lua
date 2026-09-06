local isEscorted = false
local vehicleDict = 'veh@low@front_ps@idle_duck'
local vehicleAnim = 'sit'
local LastStandCuffedDict = 'dead'
local LastStandCuffedAnim = 'dead_f'
-- Stationary pose for whenever IsCrawling (laststand.lua) is false - the
-- same vanilla "wounded ped writhing on the ground" anim this project used
-- before the crawl-and-move rework, confirmed to actually exist (unlike a
-- couple of guessed alternatives that didn't - see laststand.lua's pcall
-- comment). Similar in theme to the moving crawl pose (down, in pain),
-- just for when nothing is actually being crawled toward.
local LastStandIdleDict = 'combat@damage@writhe'
local LastStandIdleAnim = 'writhe_loop'

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
            -- Plain animFlags 1 (LOOPING) on both - same as this server's
            -- own "/e crawl" - so the ped is actually down on the ground
            -- rather than the UPPERBODY|SECONDARY overlay a previous
            -- attempt used to let GTA's own locomotion drive movement,
            -- which let normal (standing) locomotion take over the moment
            -- [W] was pressed. Movement is handled manually instead
            -- (laststand.lua's updateCrawlMovement, independent of this
            -- anim) - IsCrawling there just says which pose to show:
            -- actively crawling toward something, or lying still.
            local dict = IsCrawling and LastStandDict or LastStandIdleDict
            local anim = IsCrawling and LastStandAnim or LastStandIdleAnim
            if not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
                lib.playAnim(cache.ped, dict, anim, 1.0, 1.0, -1, 1, 0, false, false, false)
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