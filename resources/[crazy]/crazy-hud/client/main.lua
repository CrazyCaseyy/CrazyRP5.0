local config = require 'config.client'
local sharedConfig = require 'config.shared'
local speedMultiplier = config.useMPH and 2.23694 or 3.6
local setupMinimap -- forward declared, assigned further down, called from handlers defined before that point

DisplayRadar(false)

-- State Variables
local playerState = {
    isSeatbeltOn = false,
    hasWeapon = false,
}

local hudOverrideHidden = false
local playerHudThread = nil

-- Native GTA HUD components that would otherwise render directly over/around the minimap
-- (street name, area name, vehicle name, wanted stars) - our own compass/HUD already shows
-- this info, so the native versions are just redundant clutter on top of the minimap.
local HIDDEN_HUD_COMPONENTS = { 1, 6, 7, 9 } -- WANTED_STARS, VEHICLE_NAME, AREA_NAME, STREET_NAME

CreateThread(function()
    while true do
        for i = 1, #HIDDEN_HUD_COMPONENTS do
            HideHudComponentThisFrame(HIDDEN_HUD_COMPONENTS[i])
        end
        Wait(0)
    end
end)

local function getSeatbeltStatus()
    return playerState.isSeatbeltOn
end

-- Player HUD

local function sendPlayerHud(ped)
    if hudOverrideHidden then return end
    if LocalPlayer.state.invOpen or IsPauseMenuActive() then
        SendNUIMessage({ action = 'setVisible', data = { resource = 'PLAYERHUDVISABLE', state = false, data = {} } })
        return
    end

    local health = math.ceil(GetEntityHealth(ped) - 100)
    local armor = math.ceil(GetPedArmour(ped))
    local hunger = QBX.PlayerData.metadata.hunger
    local thirst = QBX.PlayerData.metadata.thirst
    local stress = QBX.PlayerData.metadata.stress

    SendNUIMessage({ action = 'setVisible', data = { resource = 'PLAYERHUDVISABLE', state = true, data = {} } })
    SendNUIMessage({
        action = 'updatePlayerHud',
        data = {
            HEALTH = health,
            ARMOUR = armor,
            HUNGER = hunger,
            THIRST = thirst,
            STRESS = stress,
        }
    })
end

local function startPlayerHudLoop(ped)
    if playerHudThread then return end

    playerHudThread = CreateThread(function()
        while cache.ped do
            if LocalPlayer.state.isLoggedIn then
                sendPlayerHud(cache.ped)
            end
            Wait(300)
        end
        SendNUIMessage({ action = 'setVisible', data = { resource = 'PLAYERHUDVISABLE', state = false, data = {} } })
        playerHudThread = nil
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    hudOverrideHidden = false
    startPlayerHudLoop(cache.ped)
    DisplayRadar(false)
    setupMinimap()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    playerHudThread = nil
    hudOverrideHidden = false
    SendNUIMessage({ action = 'setVisible', data = { resource = 'PLAYERHUDVISABLE', state = false, data = {} } })
    setVehicleHudVisible(false)
    DisplayRadar(false)
    resetLastValues()
end)

-- Hide / show HUD commands

AddEventHandler('core-hud:client:hidehud', function(state)
    hudOverrideHidden = not state

    SendNUIMessage({ action = 'setVisible', data = { resource = 'PLAYERHUDVISABLE', state = state, data = {} } })

    if cache.vehicle then
        SendNUIMessage({ action = 'setVisible', data = { resource = 'VEHICLEHUDVISABLE', state = state, data = {} } })
    end
end)

RegisterCommand('hidehud', function()
    TriggerEvent('core-hud:client:hidehud', false)
end)

RegisterCommand('showhud', function()
    TriggerEvent('core-hud:client:hidehud', true)
end)

-- Seatbelt

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    if cache.vehicle then
        playerState.isSeatbeltOn = not playerState.isSeatbeltOn
    end
end)

AddStateBagChangeHandler('seatbelt', ('player:%s'):format(cache.serverId), function(_, _, value)
    playerState.isSeatbeltOn = value and true or false
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if not cache.vehicle and playerState.isSeatbeltOn then
                playerState.isSeatbeltOn = false
            end
        end
        Wait(5000)
    end
end)

-- Low fuel / hunger / thirst notifications

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if cache.vehicle and not IsThisModelABicycle(GetEntityModel(cache.vehicle)) then
                if GetVehicleFuelLevel(cache.vehicle) <= 20 and sharedConfig.menu.isLowFuelChecked then
                    lib.notify({ description = locale('notify.low_fuel'), type = 'error', duration = 10000 })
                    Wait(60000)
                end
            end

            local hunger = QBX.PlayerData.metadata.hunger
            local thirst = QBX.PlayerData.metadata.thirst

            if hunger and hunger < 20 then
                lib.notify({ description = locale('notify.starving'), type = 'error', duration = 10000 })
                Wait(60000)
            end

            if thirst and thirst < 20 then
                lib.notify({ description = locale('notify.dehydrated'), type = 'error', duration = 10000 })
                Wait(60000)
            end
        end
        Wait(10000)
    end
end)

-- Direction / crossroads helpers

local lastCrossroadUpdate = 0
local lastCrossroadCheck = nil

local function getDirectionFromHeading(heading)
    if     heading >= 22.5  and heading < 67.5  then return 'NW'
    elseif heading >= 67.5  and heading < 112.5 then return 'W'
    elseif heading >= 112.5 and heading < 157.5 then return 'SW'
    elseif heading >= 157.5 and heading < 202.5 then return 'S'
    elseif heading >= 202.5 and heading < 247.5 then return 'SE'
    elseif heading >= 247.5 and heading < 292.5 then return 'E'
    elseif heading >= 292.5 and heading < 337.5 then return 'NE'
    else                                              return 'N'
    end
end

local function getCrossroads()
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 1500 then
        local pos = GetEntityCoords(cache.ped)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        street1 = GetStreetNameFromHashKey(street1)
        street2 = GetStreetNameFromHashKey(street2)
        lastCrossroadCheck = street2 ~= '' and (street1 .. ' x ' .. street2) or street1
    end
    return lastCrossroadCheck
end

-- Vehicle HUD

local lastSpeed = -1
local lastGear = -1
local lastRpm = -1
local lastFuel = -1
local lastSeatbelt = nil
local hudThread = nil

local function sendVehicleHud(vehicle)
    local realSpeed = math.ceil(GetEntitySpeed(vehicle) * speedMultiplier)
    local gear = GetVehicleCurrentGear(vehicle)
    local rpm = math.floor(GetVehicleCurrentRpm(vehicle) * 100)
    local vehicleFuel = math.floor(math.min((Entity(vehicle).state.fuel or 100), 100))
    local seatbelt = getSeatbeltStatus()
    local gearDisplay = IsControlPressed(0, 233) and 'R' or (gear == 0 and 'N' or tostring(gear))

    if realSpeed   == lastSpeed
    and gearDisplay == lastGear
    and rpm         == lastRpm
    and vehicleFuel == lastFuel
    and seatbelt    == lastSeatbelt
    then return end

    lastSpeed    = realSpeed
    lastGear     = gearDisplay
    lastRpm      = rpm
    lastFuel     = vehicleFuel
    lastSeatbelt = seatbelt

    SendNUIMessage({
        action = 'updateVehicleHud',
        data = {
            SPEED        = realSpeed,
            GEAR         = gearDisplay,
            SPEEDPERCENT = rpm,
            FUELPERCENT  = vehicleFuel,
            isSeatBeltOn = seatbelt,
        }
    })
end

local lastStreet = ''
local lastZone = ''
local lastDir = ''
local lastHeading = -1

local function sendStreetData(ped)
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local zoneName = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))
    local street = getCrossroads()
    local direction = getDirectionFromHeading(heading)
    local roundedHeading = math.floor(heading + 0.5)

    if street     == lastStreet
    and zoneName  == lastZone
    and direction == lastDir
    and math.abs(roundedHeading - lastHeading) < 1
    then return end

    lastStreet  = street
    lastZone    = zoneName
    lastDir     = direction
    lastHeading = roundedHeading

    SendNUIMessage({
        action = 'updateStreetName',
        data = {
            DIRECTION          = direction,
            MAIN_STREET        = street,
            SECONDARY_LOCATION = zoneName,
            HEADING            = heading,
        }
    })
end

function setVehicleHudVisible(state)
    SendNUIMessage({ action = 'setVisible', data = { resource = 'VEHICLEHUDVISABLE', state = state, data = {} } })
end

function resetLastValues()
    lastSpeed    = -1
    lastGear     = -1
    lastRpm      = -1
    lastFuel     = -1
    lastSeatbelt = nil
    lastStreet   = ''
    lastZone     = ''
    lastDir      = ''
    lastHeading  = -1
end

local function startHudLoop(vehicle)
    if hudThread then return end

    hudThread = CreateThread(function()
        local hudShowing = false

        while cache.vehicle do
            local v = cache.vehicle

            if config.noHudVehicles[GetEntityModel(v)] then
                if hudShowing then
                    setVehicleHudVisible(false)
                    DisplayRadar(false)
                    hudShowing = false
                    resetLastValues()
                end
                Wait(300)
            elseif GetIsVehicleEngineRunning(v) and not IsPauseMenuActive() and not LocalPlayer.state.invOpen and not hudOverrideHidden then
                if not hudShowing then
                    setVehicleHudVisible(true)
                    DisplayRadar(true)
                    hudShowing = true
                end
                sendVehicleHud(v)
                sendStreetData(cache.ped)
                Wait(0)
            else
                if hudShowing then
                    setVehicleHudVisible(false)
                    DisplayRadar(false)
                    hudShowing = false
                    resetLastValues()
                end
                Wait(300)
            end
        end

        if hudShowing then
            setVehicleHudVisible(false)
            DisplayRadar(false)
        end
        resetLastValues()
        hudThread = nil
    end)
end

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        startHudLoop(vehicle)
    else
        setVehicleHudVisible(false)
        DisplayRadar(false)
        resetLastValues()
    end
end)

-- Catch up on current state when the resource (re)starts mid-session, since QBCore:Client:OnPlayerLoaded
-- and lib.onCache('vehicle', ...) only fire on future transitions, not for a state we're already in.
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    if LocalPlayer.state.isLoggedIn then
        startPlayerHudLoop(cache.ped)
        setupMinimap()
        if cache.vehicle then
            startHudLoop(cache.vehicle)
        end
    end
end)

-- Radar / minimap setup

local minimapConfigured = false
local healthArmourHideThread = nil

-- The minimap scaleform draws its own health/armour bars unless told otherwise every frame -
-- calling SETUP_HEALTH_ARMOUR with type 3 (the "golf" HUD mode) is the standard way to make it
-- stop drawing them, since there's no simple HideHudComponentThisFrame ID for this element.
local function startHealthArmourHideThread(minimap)
    if healthArmourHideThread then return end
    healthArmourHideThread = CreateThread(function()
        while true do
            BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
            Wait(0)
        end
    end)
end

function setupMinimap()
    local minimap = RequestScaleformMovie('minimap')
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        local attempts = 0
        while not HasScaleformMovieLoaded(minimap) and attempts < 500 do
            Wait(10)
            attempts = attempts + 1
        end
        if not HasScaleformMovieLoaded(minimap) then return end
    end
    startHealthArmourHideThread(minimap)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    DisplayRadar(false)

    local defaultAspectRatio = 1920 / 1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapXOffset, minimapYOffset = 0, -0.070

    if aspectRatio > defaultAspectRatio then
        local aspectDifference = defaultAspectRatio - aspectRatio
        minimapXOffset = aspectDifference / 3.6
    end

    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045 + minimapXOffset, 0.002 + minimapYOffset, 0.150, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020 + minimapXOffset, 0.030 + minimapYOffset, 0.111, 0.159)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03 + minimapXOffset, 0.022 + minimapYOffset, 0.266, 0.237)

    local northBlip = GetNorthRadarBlip()
    if northBlip then SetBlipAlpha(northBlip, 0) end

    minimapConfigured = true
end

CreateThread(setupMinimap)

-- Voice

local voiceRange = 2
local talkingOnRadio = false

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    voiceRange = tonumber(mode)
end)

AddEventHandler('pma-voice:radioActive', function(radioTalking)
    talkingOnRadio = radioTalking
end)

CreateThread(function()
    while true do
        SendNUIMessage({
            action = 'updateVoiceState',
            data = {
                VOICERANGE = voiceRange,
                VOICESTATE = NetworkIsPlayerTalking(PlayerId()),
                RADIOTALK  = talkingOnRadio,
                ONPHONE    = LocalPlayer.state['callChannel'] or 0 > 0,
            }
        })
        Wait(200)
    end
end)

-- Stress

local function getBlurIntensity(stressLevel)
    for _, v in ipairs(config.stress.blurIntensity) do
        if stressLevel >= v.min and stressLevel <= v.max then return v.intensity end
    end
    return 1500
end

local function getEffectInterval(stressLevel)
    for _, v in ipairs(config.stress.effectInterval) do
        if stressLevel >= v.min and stressLevel <= v.max then return v.timeout end
    end
    return 60000
end

local function isWhitelistedWeaponStress(weapon)
    for _, v in ipairs(config.stress.whitelistedWeapons) do
        if weapon == v then return true end
    end
    return false
end

local function startWeaponStressThread(weapon)
    if isWhitelistedWeaponStress(weapon) then return end
    playerState.hasWeapon = true

    CreateThread(function()
        while playerState.hasWeapon do
            if IsPedShooting(cache.ped) and math.random() <= config.stress.chance then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 5))
            end
            Wait(0)
        end
    end)
end

AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
    playerState.hasWeapon = false
    Wait(0)
    if currentWeapon then startWeaponStressThread(currentWeapon.hash) end
end)

if sharedConfig.stress.enableStress then
    CreateThread(function()
        while true do
            if LocalPlayer.state.isLoggedIn and cache.vehicle then
                local vehClass = GetVehicleClass(cache.vehicle)
                local speed = GetEntitySpeed(cache.vehicle) * speedMultiplier

                if vehClass ~= 13 and vehClass ~= 14 and vehClass ~= 15
                and vehClass ~= 16 and vehClass ~= 21 and vehClass ~= 8 then
                    local stressSpeed = (vehClass == 8 or not playerState.isSeatbeltOn)
                        and config.stress.minForSpeedingUnbuckled
                        or  config.stress.minForSpeeding
                    if speed >= stressSpeed then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            end
            Wait(10000)
        end
    end)

    CreateThread(function()
        while true do
            if LocalPlayer.state.isLoggedIn and QBX.PlayerData.metadata then
                local stresslevels = QBX.PlayerData.metadata.stress or 0

                if stresslevels >= 100 then
                    local blurIntensity = getBlurIntensity(stresslevels)
                    local fallRepeat = math.random(2, 4)
                    local ragdollTimeout = fallRepeat * 1750

                    TriggerScreenblurFadeIn(1000.0)
                    Wait(blurIntensity)
                    TriggerScreenblurFadeOut(1000.0)

                    if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                        local fv = GetEntityForwardVector(cache.ped)
                        SetPedToRagdollWithFall(cache.ped, ragdollTimeout, ragdollTimeout, 1, fv.x, fv.y, fv.z, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                    end

                    Wait(1000)
                    for _ = 1, fallRepeat do
                        Wait(750)
                        DoScreenFadeOut(200)
                        Wait(1000)
                        DoScreenFadeIn(200)
                        TriggerScreenblurFadeIn(1000.0)
                        Wait(blurIntensity)
                        TriggerScreenblurFadeOut(1000.0)
                    end
                elseif stresslevels >= config.stress.minForShaking then
                    local blurIntensity = getBlurIntensity(stresslevels)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(blurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end

                Wait(getEffectInterval(stresslevels))
            else
                Wait(1000)
            end
        end
    end)
end

-- Ammo Counter

local lastAmmoState = { visible = nil, clip = nil, reserve = nil }

local function sendAmmoCounter(visible, clip, reserve)
    if lastAmmoState.visible == visible and lastAmmoState.clip == clip and lastAmmoState.reserve == reserve then return end
    lastAmmoState.visible = visible
    lastAmmoState.clip = clip
    lastAmmoState.reserve = reserve
    SendNUIMessage({
        action = 'ammoCounter',
        data = { visible = visible, clip = clip or 0, reserve = reserve or 0 }
    })
end

local function hideAmmoCounter()
    sendAmmoCounter(false, 0, 0)
end

CreateThread(function()
    while true do
        local ped = cache.ped or PlayerPedId()

        if not DoesEntityExist(ped)
            or IsPauseMenuActive()
            or LocalPlayer.state.invOpen
            or not IsPedArmed(ped, 4)
        then
            hideAmmoCounter()
            Wait(250)
        else
            local weapon = GetSelectedPedWeapon(ped)

            if weapon == `WEAPON_UNARMED` or weapon == 0 then
                hideAmmoCounter()
                Wait(250)
            else
                local hasClip, clipAmmo = GetAmmoInClip(ped, weapon)
                local totalAmmo = GetAmmoInPedWeapon(ped, weapon)

                if not hasClip then
                    hideAmmoCounter()
                    Wait(250)
                else
                    local reserveAmmo = math.max(totalAmmo - clipAmmo, 0)
                    sendAmmoCounter(true, clipAmmo, reserveAmmo)
                    Wait(IsPedShooting(ped) and 0 or 120)
                end
            end
        end
    end
end)

-- Engine start prompt (driver seat, engine off) - queries qbx_vehiclekeys' actual keybind
-- via its hash rather than duplicating the RegisterKeyMapping, so player rebinds are respected
-- without risking a second registration of the same control.

local engineBindHash = joaat('+toggleengine') | 0x80000000
local lastEnginePromptKey = nil

CreateThread(function()
    while true do
        local shouldShow = LocalPlayer.state.isLoggedIn
            and cache.vehicle
            and cache.seat == -1
            and not GetIsVehicleEngineRunning(cache.vehicle)
            and not IsPauseMenuActive()
            and not LocalPlayer.state.invOpen

        if shouldShow then
            local key = GetControlInstructionalButton(0, engineBindHash, true):sub(3)
            if key ~= lastEnginePromptKey then
                SendNUIMessage({ action = 'engineStartPrompt', show = true, key = key })
                lastEnginePromptKey = key
            end
        elseif lastEnginePromptKey ~= nil then
            SendNUIMessage({ action = 'engineStartPrompt', show = false })
            lastEnginePromptKey = nil
        end

        Wait(500)
    end
end)
