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
            -- Always the same crawl pose whether actually moving or not -
            -- an earlier attempt swapped to a different anim (dead_a) while
            -- idle, but blending between that (lying on the back) and this
            -- (prone on the front) is such a different pose that it visibly
            -- glitched the character switching between them. Plain
            -- animFlags 1 (LOOPING), same as this server's own "/e crawl",
            -- so the ped is actually down on the ground rather than the
            -- UPPERBODY|SECONDARY overlay a previous attempt used to let
            -- GTA's own locomotion drive movement, which let normal
            -- (standing) locomotion take over the moment [W] was pressed.
            -- Movement itself is handled entirely separately (laststand.lua's
            -- updateCrawlMovement) - this anim doesn't change based on it.
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