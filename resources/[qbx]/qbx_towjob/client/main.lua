local config = require 'config.client'
local sharedConfig = require 'config.shared'
local PlayerJob = {}
local JobsDone = 0
local NpcOn = false
local CurrentLocation = {}
local CurrentBlip = nil
local CurrentBlip2 = nil
local CurrentTow = nil
local LastVehicle = 0

-- Functions

local function getRandomVehicleLocation()
    local randomVehicle = math.random(1, #sharedConfig.locations["towspots"])
    while randomVehicle == LastVehicle do
        Wait(10)
        randomVehicle = math.random(1, #sharedConfig.locations["towspots"])
    end
    return randomVehicle
end

local function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, cache.ped, 0)
	local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

local function isTowVehicle(vehicle)
    for k in pairs(config.vehicles) do
        if GetEntityModel(vehicle) == joaat(k) then
            return true
        end
    end
    return false
end

local function CreateZone(type, number)
    local coords
    local heading
    local boxName
    local event
    local label
    local size

    if type == "towspots" then
        event = "qb-tow:client:SpawnNPCVehicle"
        label = locale("label.npcz")
        coords = sharedConfig.locations[type][number].coords.xyz
        heading = sharedConfig.locations["towspots"][number].coords.w --[[@as number?]]
        boxName = sharedConfig.locations["towspots"][number].name
        size = vec3(50, 50, 10)
    else
        return
    end

    if config.useTarget then
        exports.ox_target:addBoxZone({
            name = boxName,
            coords = coords,
            size = size,
            rotation = heading,
            debug = config.debugPoly,
            options = {
                {
                    event = event,
                    label = label,
                    distance = 2,
                }
            }
        })
    else
        local zone = lib.zones.box({
            coords = coords,
            size = size,
            rotation = heading,
            debug = config.debugPoly,
            onEnter = function()
                TriggerEvent(event)
            end,
        })
        CurrentLocation.zoneCombo = zone
    end
end

local function deliverVehicle(vehicle)
    DeleteVehicle(vehicle)
    RemoveBlip(CurrentBlip2)
    JobsDone += 1
    exports.qbx_core:Notify(locale("mission.delivered_vehicle"), "success")
    exports.qbx_core:Notify(locale("mission.get_new_vehicle"))

    local randomLocation = getRandomVehicleLocation()
    CurrentLocation.x = sharedConfig.locations["towspots"][randomLocation].coords.x
    CurrentLocation.y = sharedConfig.locations["towspots"][randomLocation].coords.y
    CurrentLocation.z = sharedConfig.locations["towspots"][randomLocation].coords.z
    CurrentLocation.model = sharedConfig.locations["towspots"][randomLocation].model
    CurrentLocation.id = randomLocation
    CreateZone("towspots", randomLocation)

    CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
    SetBlipColour(CurrentBlip, 3)
    SetBlipRoute(CurrentBlip, true)
    SetBlipRouteColour(CurrentBlip, 3)
end

-- Ends the job: returns/deletes the flatbed and cashes out whatever's
-- been delivered since it started.
local function endJob(flatbed)
    if flatbed and DoesEntityExist(flatbed) then
        DeleteVehicle(flatbed)
    end

    if DoesBlipExist(CurrentBlip) then RemoveBlip(CurrentBlip) end
    if DoesBlipExist(CurrentBlip2) then RemoveBlip(CurrentBlip2) end
    if CurrentLocation.zoneCombo then
        CurrentLocation.zoneCombo:remove()
        CurrentLocation.zoneCombo = nil
    end

    local drops = JobsDone
    NpcOn = false
    JobsDone = 0
    CurrentLocation = {}
    CurrentTow = nil

    if drops > 0 then
        TriggerServerEvent('qb-tow:server:cashOut', drops)
    else
        exports.qbx_core:Notify(locale("mission.vehicle_takenoff"), "success")
    end
end

local function startJob()
    if NpcOn then
        exports.qbx_core:Notify(locale("info.already_working"), "error")
        return
    end

    local netId = lib.callback.await('qb-tow:server:startJob', false)
    if not netId then
        exports.qbx_core:Notify(locale("error.no_flatbed"), "error")
        return
    end

    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and veh ~= 0 then
        SetVehicleEngineOn(veh, true, true, false)
        for i = 1, 9, 1 do
            SetVehicleExtra(veh, i, false)
        end
    end

    NpcOn = true
    JobsDone = 0

    local randomLocation = getRandomVehicleLocation()
    CurrentLocation.x = sharedConfig.locations["towspots"][randomLocation].coords.x
    CurrentLocation.y = sharedConfig.locations["towspots"][randomLocation].coords.y
    CurrentLocation.z = sharedConfig.locations["towspots"][randomLocation].coords.z
    CurrentLocation.model = sharedConfig.locations["towspots"][randomLocation].model
    CurrentLocation.id = randomLocation
    CreateZone("towspots", randomLocation)

    CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
    SetBlipColour(CurrentBlip, 3)
    SetBlipRoute(CurrentBlip, true)
    SetBlipRouteColour(CurrentBlip, 3)

    exports.qbx_core:Notify(locale("info.job_started"), "success")
end

-- Clipboard ped

local pedSpawned = false

-- Same reasoning as crazy-dailytasks/crazy-carrental's own peds: don't
-- race the whole-server asset-streaming storm on a fresh boot -
-- lib.requestModel throws (not returns false) on timeout, silently
-- killing this thread with no retry, so wait for the player to actually
-- be loaded in instead.
local function SpawnPed()
    if pedSpawned then return end
    pedSpawned = true

    local model = joaat(config.ped.model)
    local ok = pcall(lib.requestModel, model, 10000)
    if not ok or not HasModelLoaded(model) then
        print(('^1[qbx_towjob]^7 failed to load ped model %s - clipboard ped was not spawned'):format(config.ped.model))
        pedSpawned = false
        return
    end

    local coords = sharedConfig.locations["start"].coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 then
        print('^1[qbx_towjob]^7 CreatePed returned an invalid entity - clipboard ped was not spawned')
        pedSpawned = false
        return
    end

    SetPedDefaultComponentVariation(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, config.ped.scenario, 0, true)

    exports.ox_target:addLocalEntity(ped, {{
        name = 'qbx_towjob_start',
        icon = 'fa-solid fa-truck-pickup',
        label = locale("label.start_job"),
        distance = 1.5,
        onSelect = startJob,
    }})

    local depotBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(depotBlip, 477)
    SetBlipDisplay(depotBlip, 4)
    SetBlipScale(depotBlip, 0.6)
    SetBlipAsShortRange(depotBlip, true)
    SetBlipColour(depotBlip, 15)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(sharedConfig.locations["start"].label)
    EndTextCommandSetBlipName(depotBlip)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', SpawnPed)

if LocalPlayer.state.isLoggedIn then
    SpawnPed()
end

-- Events

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

-- No longer requires the tow job - anyone can toggle a tow spot.
RegisterNetEvent('jobs:client:ToggleNpc', function()
    if NpcOn then
        exports.qbx_core:Notify(locale("error.finish_work"), "error")
        return
    end
    startJob()
end)

RegisterNetEvent('qb-tow:client:TowVehicle', function()
    local vehicle = cache.vehicle
    if isTowVehicle(vehicle) then
        if not CurrentTow then
            local coordA = GetEntityCoords(cache.ped)
            local coordB = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -30.0, 0.0)
            local targetVehicle = getVehicleInDirection(coordA, coordB)

            if NpcOn and CurrentLocation then
                if GetEntityModel(targetVehicle) ~= joaat(CurrentLocation.model) then
                    exports.qbx_core:Notify(locale("error.vehicle_not_correct"), "error")
                    return
                end
            end

            if cache.vehicle then
                if vehicle ~= targetVehicle then
                    local towPos = GetEntityCoords(vehicle)
                    local targetPos = GetEntityCoords(targetVehicle)
                    if #(towPos - targetPos) < 11.0 then
                        if lib.progressBar({
                            duration = 5000,
                            label = locale("mission.towing_vehicle"),
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                            },
                            anim = {
                                dict = 'mini@repair',
                                clip = 'fixing_a_ped'
                            },
                        }) then
                            StopAnimTask(cache.ped, "mini@repair", "fixing_a_ped", 1.0)
                            AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0, -1.5 + -0.85, 0.0 + 1.15, 0, 0, 0, true, true, false, true, 0, true)
                            FreezeEntityPosition(targetVehicle, true)
                            CurrentTow = targetVehicle
                            if NpcOn then
                                RemoveBlip(CurrentBlip)
                                exports.qbx_core:Notify(locale("mission.goto_depot"), "inform", 5000)
                                CurrentBlip2 = AddBlipForCoord(sharedConfig.locations["vehicle"].coords.x, sharedConfig.locations["vehicle"].coords.y, sharedConfig.locations["vehicle"].coords.z)
                                SetBlipColour(CurrentBlip2, 3)
                                SetBlipRoute(CurrentBlip2, true)
                                SetBlipRouteColour(CurrentBlip2, 3)
                                --remove zone
                                CurrentLocation.zoneCombo:remove()
                            end
                            exports.qbx_core:Notify(locale("mission.vehicle_towed"), "success")
                        else
                            StopAnimTask(cache.ped, "mini@repair", "fixing_a_ped", 1.0)
                            exports.qbx_core:Notify(locale("error.failed"), "error")
                        end
                    end
                end
            end
        else
            if lib.progressBar({
                duration = 5000,
                label = locale("mission.untowing_vehicle"),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                },
                anim = {
                    dict = 'mini@repair',
                    clip = 'fixing_a_ped'
                },
            }) then
                StopAnimTask(cache.ped, "mini@repair", "fixing_a_ped", 1.0)
                FreezeEntityPosition(CurrentTow, false)
                Wait(250)
                AttachEntityToEntity(CurrentTow, vehicle, 20, -0.0, -15.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                DetachEntity(CurrentTow, true, true)
                if NpcOn then
                    local targetPos = GetEntityCoords(CurrentTow)
                    if #(targetPos - sharedConfig.locations["vehicle"].coords.xyz) < 25.0 then
                        deliverVehicle(CurrentTow)
                    end
                end
                RemoveBlip(CurrentBlip2)
                CurrentTow = nil
                exports.qbx_core:Notify(locale("mission.vehicle_takenoff"), "success")
            else
                StopAnimTask(cache.ped, "mini@repair", "fixing_a_ped", 1.0)
                exports.qbx_core:Notify(locale("error.failed"), "error")
            end
        end
    else
        exports.qbx_core:Notify(locale("error.not_towing_vehicle"), "error")
    end
end)

RegisterNetEvent('qb-tow:client:SpawnNPCVehicle', function()
    local netId = lib.callback.await('qb-tow:server:spawnVehicle', false, CurrentLocation.model, vec3(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z))
    NetToVeh(netId)
end)

-- Threads

-- Flatbed hub marker + return prompt - only while a job is actually
-- active, and only offering to return once there's a flatbed actually
-- parked there (not just standing in the zone).
CreateThread(function()
    local hubCoords = sharedConfig.locations["vehicle"].coords
    local promptShown = false

    while true do
        Wait(0)
        if not NpcOn then
            if promptShown then
                lib.hideTextUI()
                promptShown = false
            end
            Wait(500)
        else
            DrawMarker(1, hubCoords.x, hubCoords.y, hubCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 220, 0, 0, 120, false, false, 2, false, nil, nil, false)

            if #(GetEntityCoords(cache.ped) - hubCoords.xyz) < 3.0 then
                local flatbed = lib.getClosestVehicle(hubCoords.xyz, 5.0, true)
                if flatbed and isTowVehicle(flatbed) then
                    if not promptShown then
                        lib.showTextUI(locale("label.return_vehicle"), { position = 'right-center' })
                        promptShown = true
                    end
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        promptShown = false
                        endJob(flatbed)
                    end
                elseif promptShown then
                    lib.hideTextUI()
                    promptShown = false
                end
            elseif promptShown then
                lib.hideTextUI()
                promptShown = false
            end
        end
    end
end)
