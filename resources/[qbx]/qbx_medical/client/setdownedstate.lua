local isEscorted = false
local vehicleDict = 'veh@low@front_ps@idle_duck'
local vehicleAnim = 'sit'
local LastStandCuffedDict = 'dead'
local LastStandCuffedAnim = 'dead_f'

-- Tracks whether the last time the crawl anim was (re)applied it was
-- looping or held still, so a change in IsCrawling (laststand.lua) always
-- re-issues the anim with the right flag even though IsEntityPlayingAnim
-- already says "yes" for either flag (it only checks dict+clip, not which
-- flags started it) - without this, switching from moving to idle (or
-- back) would never actually take effect below.
local lastAppliedIsCrawling = nil

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
            -- Always the same crawl pose whether actually moving or not -
            -- an earlier attempt swapped to a different anim (dead_a) while
            -- idle, but blending between that (lying on the back) and this
            -- (prone on the front) is such a different pose that it visibly
            -- glitched the character switching between them. What changes
            -- instead is the anim flag: 1 (LOOPING) while IsCrawling
            -- (laststand.lua) is true, so the limbs actively cycle through
            -- the crawl motion; 2 (HOLD_LAST_FRAME, no loop) while it's
            -- false, freezing the pose on a single still frame instead of
            -- endlessly playing the crawl cycle in place - which is what
            -- would otherwise look wrong/desynced to anyone else watching,
            -- since the limbs would keep moving with no matching
            -- translation. Movement itself is handled entirely separately
            -- (laststand.lua's updateCrawlMovement).
            local animFlags = IsCrawling and 1 or 2
            if lastAppliedIsCrawling ~= IsCrawling or not IsEntityPlayingAnim(cache.ped, LastStandDict, LastStandAnim, 3) then
                lib.playAnim(cache.ped, LastStandDict, LastStandAnim, 1.0, 1.0, -1, animFlags, 0, false, false, false)
                lastAppliedIsCrawling = IsCrawling
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