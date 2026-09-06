local config = require 'config.client'
local sharedConfig = require 'config.shared'
local doctorCount = 0

local function getDoctorCount()
    return lib.callback.await('qbx_ambulancejob:server:getNumDoctors')
end

-- The countdown text this used to draw (info.respawn_txt / info.respawn_revive)
-- now comes from client/deathscreen.lua's NUI instead - left as a no-op
-- so handleDead()'s call site below doesn't need touching.
local function displayRespawnText()
end

---@param ped number
local function playDeadAnimation(ped)
    if IsInHospitalBed then
        if not IsEntityPlayingAnim(ped, InBedDict, InBedAnim, 3) then
            lib.playAnim(ped, InBedDict, InBedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        exports.qbx_medical:PlayDeadAnimation()
    end
end

---@param ped number
local function handleDead(ped)
    if not IsInHospitalBed then
        displayRespawnText()
    end

    playDeadAnimation(ped)
end

---Player is able to send a notification to EMS there are any on duty
local function handleRequestingEms()
    if not EmsNotified then
        qbx.drawText2d({ text = locale('info.request_help'), coords = vec2(1.0, 1.40), scale = 0.6 })
        if IsControlJustPressed(0, 47) then
            TriggerServerEvent('hospital:server:ambulanceAlert', locale('info.civ_down'))
            EmsNotified = true
        end
    else
        qbx.drawText2d({ text = locale('info.help_requested'), coords = vec2(1.0, 1.40), scale = 0.6 })
    end
end

-- The bleed_out / bleed_out_help countdown text this used to draw is now
-- shown by client/deathscreen.lua's NUI instead - this only still decides
-- whether the EMS-alert hotkey hint (handleRequestingEms) should run.
local function handleLastStand()
    local laststandTime = exports.qbx_medical:GetLaststandTime()
    if laststandTime <= config.laststandTimer and doctorCount > 0 then
        handleRequestingEms()
    end
end

---Set dead and last stand states.
CreateThread(function()
    local lastUpdate = GetGameTimer()
    while true do
        local isDead = exports.qbx_medical:IsDead()
        local inLaststand = exports.qbx_medical:IsLaststand()
        if isDead or inLaststand then
            if isDead then
                handleDead(cache.ped)
            elseif inLaststand then
                handleLastStand()
            end

            local currentTime = GetGameTimer()
            if (currentTime - lastUpdate) > 60000 then
                doctorCount = getDoctorCount()
                lastUpdate = currentTime
            end

            Wait(0)
        else
            Wait(1000)
        end
    end
end)
