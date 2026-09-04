local config = require 'config.client'
local sharedConfig = require 'config.shared'
local route = 1
local max = #sharedConfig.npcLocations.locations
local busBlip = nil
local deliverZone
local pickupZone
local pedSpawned = false
local routeTotal = 0

local NpcData = {
    Active = false,
    LastNpc = nil,
    LastDeliver = nil,
    Npc = nil,
    NpcBlip = nil,
    DeliveryBlip = nil,
    NpcTaken = false,
    NpcDelivered = false,
    CountDown = 180
}

local BusData = {
    Active = false,
}

-- Functions
local function resetNpcTask()
    NpcData = {
        Active = false,
        LastNpc = nil,
        LastDeliver = nil,
        Npc = nil,
        NpcBlip = nil,
        DeliveryBlip = nil,
        NpcTaken = false,
        NpcDelivered = false,
    }
end

local function removeBusBlip()
    if not busBlip then return end
    RemoveBlip(busBlip)
    busBlip = nil
end

local function removeNPCBlip()
    if NpcData.DeliveryBlip then
        RemoveBlip(NpcData.DeliveryBlip)
        NpcData.DeliveryBlip = nil
    end

    if NpcData.NpcBlip then
        RemoveBlip(NpcData.NpcBlip)
        NpcData.NpcBlip = nil
    end
end

-- No longer requires the bus job - anyone can drive the bus, so the depot
-- blip is always shown once player data is available.
local function updateBlip()
    if table.type(QBX.PlayerData) == 'empty' then
        removeBusBlip()
        return
    elseif not busBlip then
        local coords = config.ped.coords
        busBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(busBlip, 513)
        SetBlipDisplay(busBlip, 4)
        SetBlipScale(busBlip, 0.6)
        SetBlipAsShortRange(busBlip, true)
        SetBlipColour(busBlip, 49)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(locale('info.bus_depot'))
        EndTextCommandSetBlipName(busBlip)
        return
    end
end

local function isPlayerVehicleABus()
    if not cache.vehicle then return false end
    local veh = GetEntityModel(cache.vehicle)

    for i = 1, #config.allowedVehicles, 1 do
        if veh == config.allowedVehicles[i].model then
            return true
        end
    end

    if veh == `dynasty` then
        return true
    end

    return false
end

local function nextStop()
    route = route <= (max - 1) and route + 1 or 1
end

local function removePed(ped)
    SetTimeout(60000, function()
        DeletePed(ped)
    end)
end

local function getDeliveryLocation()
    nextStop()
    removeNPCBlip()
    NpcData.DeliveryBlip = AddBlipForCoord(sharedConfig.npcLocations.locations[route].x, sharedConfig.npcLocations.locations[route].y, sharedConfig.npcLocations.locations[route].z)
    SetBlipColour(NpcData.DeliveryBlip, 3)
    SetBlipRoute(NpcData.DeliveryBlip, true)
    SetBlipRouteColour(NpcData.DeliveryBlip, 3)
    NpcData.LastDeliver = route
    local inRange = false
    local shownTextUI = false
    deliverZone = lib.zones.sphere({
        name = "qbx_busjob_bus_deliver",
        coords = vec3(sharedConfig.npcLocations.locations[route].x, sharedConfig.npcLocations.locations[route].y, sharedConfig.npcLocations.locations[route].z),
        radius = 5,
        debug = config.debugPoly,
        onEnter = function()
            inRange = true
            if not shownTextUI then
                lib.showTextUI(locale('info.busstop_text'))
                shownTextUI = true
            end
            CreateThread(function()
                repeat
                    Wait(0)
                    if IsControlJustPressed(0, 38) then
                        TaskLeaveVehicle(NpcData.Npc, cache.vehicle, 0)
                        SetEntityAsMissionEntity(NpcData.Npc, false, true)
                        SetEntityAsNoLongerNeeded(NpcData.Npc)
                        local targetCoords = sharedConfig.npcLocations.locations[NpcData.LastNpc]
                        TaskGoStraightToCoord(NpcData.Npc, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)

                        local payment = lib.callback.await('qbx_busjob:server:NpcPay', false)
                        if payment then
                            routeTotal += payment
                            lib.notify({
                                title = locale('info.bus_job'),
                                description = locale('info.dropped_off_paid', payment, routeTotal),
                                type = 'success'
                            })
                        end

                        removeNPCBlip()
                        removePed(NpcData.Npc)
                        resetNpcTask()
                        nextStop()
                        TriggerEvent('qbx_busjob:client:DoBusNpc')
                        lib.hideTextUI()
                        shownTextUI = false
                        deliverZone:remove()
                        deliverZone = nil
                        break
                    end
                until not inRange
            end)
        end,
        onExit = function()
            lib.hideTextUI()
            shownTextUI = false
            inRange = false
        end
    })
end

local function startRoute()
    if BusData.Active then
        lib.notify({
            title = locale('info.bus_job'),
            description = locale('error.one_bus_active'),
            type = 'error'
        })
        return
    end

    local model = config.allowedVehicles[1].model
    local netId = lib.callback.await('qbx_busjob:server:spawnBus', false, model, config.vehicleSpawn)
    Wait(300)
    if not netId or netId == 0 or not NetworkDoesEntityExistWithNetworkId(netId) then
        lib.notify({
            title = locale('info.bus_job'),
            description = locale('error.failed_to_spawn'),
            type = 'error'
        })
        return
    end

    local veh = NetToVeh(netId)
    if veh == 0 then
        lib.notify({
            title = locale('info.bus_job'),
            description = locale('error.failed_to_spawn'),
            type = 'error'
        })
        return
    end

    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleEngineOn(veh, true, true, false)
    BusData.Active = true
    routeTotal = 0
    TriggerEvent('qbx_busjob:client:DoBusNpc')
end

-- Same reasoning as the other job peds in this server (crazy-dailytasks,
-- crazy-carrental, qbx_towjob, qbx_taxijob): lib.requestModel throws (not
-- returns false) on timeout, silently killing this thread on a fresh
-- server boot - wait for the player to actually be loaded in instead.
local function spawnPed()
    if pedSpawned then return end
    pedSpawned = true

    local model = joaat(config.ped.model)
    local ok = pcall(lib.requestModel, model, 10000)
    if not ok or not HasModelLoaded(model) then
        print(('^1[qbx_busjob]^7 failed to load ped model %s - clipboard ped was not spawned'):format(config.ped.model))
        pedSpawned = false
        return
    end

    local coords = config.ped.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 then
        print('^1[qbx_busjob]^7 CreatePed returned an invalid entity - ped was not spawned')
        pedSpawned = false
        return
    end

    SetPedDefaultComponentVariation(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, config.ped.scenario, 0, true)

    -- No 'job' filter - anyone can interact, not just the bus job.
    exports.ox_target:addLocalEntity(ped, {{
        name = 'qbx_busjob_start',
        icon = 'fa-solid fa-bus',
        label = locale('info.start_route'),
        distance = 1.5,
        onSelect = startRoute,
    }})
end

-- Single red ring on the ground at the return point - only shown while
-- an active bus is out.
local function drawEndRing(coords)
    DrawMarker(1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 220, 0, 0, 120, false, false, 2, false, nil, nil, false)
end

CreateThread(function()
    local endCoords = config.endLocation
    local promptShown = false

    while true do
        if BusData.Active then
            drawEndRing(endCoords)

            -- Matches qbx_towjob/qbx_taxijob's own return-zone pattern -
            -- checks for a parked bus nearby, not that the player is
            -- still sitting in it (they may have hopped out already).
            local nearbyBus = #(GetEntityCoords(cache.ped) - endCoords) < 3.0 and lib.getClosestVehicle(endCoords, 5.0, true)
            if nearbyBus and GetEntityModel(nearbyBus) == config.allowedVehicles[1].model then
                if NpcData.NpcTaken then
                    if not promptShown then
                        lib.showTextUI(locale('info.finish_route_first'), { position = 'right-center' })
                        promptShown = true
                    end
                else
                    if not promptShown then
                        lib.showTextUI(locale('info.end_route'), { position = 'right-center' })
                        promptShown = true
                    end
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        promptShown = false
                        BusData.Active = false
                        DeleteVehicle(nearbyBus)
                        removeNPCBlip()
                        resetNpcTask()
                        lib.notify({
                            title = locale('info.bus_job'),
                            description = locale('info.route_ended', routeTotal),
                            type = 'success'
                        })
                        routeTotal = 0
                    end
                end
            elseif promptShown then
                lib.hideTextUI()
                promptShown = false
            end

            Wait(0)
        else
            if promptShown then
                lib.hideTextUI()
                promptShown = false
            end
            Wait(500)
        end
    end
end)

-- Events
AddEventHandler('onResourceStart', function(resourceName)
    -- handles script restarts
    if GetCurrentResourceName() ~= resourceName then return end

    updateBlip()
    spawnPed()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    updateBlip()
    spawnPed()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()

    updateBlip()
    spawnPed()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()

    updateBlip()
    spawnPed()
end)

RegisterNetEvent('qbx_busjob:client:DoBusNpc', function()
    if not isPlayerVehicleABus() then
        lib.notify({
            title = locale('info.bus_job'),
            description = locale('error.not_in_bus'),
            type = 'error'
        })
        return
    end

    if not NpcData.Active then
        local Gender = math.random(1, #config.npcSkins)
        local PedSkin = math.random(1, #config.npcSkins[Gender])
        local model = joaat(config.npcSkins[Gender][PedSkin])
        lib.requestModel(model, 10000)
        NpcData.Npc = CreatePed(3, model, sharedConfig.npcLocations.locations[route].x, sharedConfig.npcLocations.locations[route].y, sharedConfig.npcLocations.locations[route].z - 0.98, sharedConfig.npcLocations.locations[route].w, false, true)
        SetModelAsNoLongerNeeded(model)
        PlaceObjectOnGroundProperly(NpcData.Npc)
        FreezeEntityPosition(NpcData.Npc, true)
        -- Stops it panicking/turning hostile as the bus pulls up -
        -- without these it can flee the pickup spot or, once the freeze
        -- above is lifted for TaskEnterVehicle, yank the player out of
        -- the driver seat.
        SetEntityInvincible(NpcData.Npc, true)
        SetBlockingOfNonTemporaryEvents(NpcData.Npc, true)
        SetPedFleeAttributes(NpcData.Npc, 0, false)
        SetPedCombatAttributes(NpcData.Npc, 46, false)
        SetPedCanRagdoll(NpcData.Npc, false)
        DisablePedPainAudio(NpcData.Npc, true)
        removeNPCBlip()
        NpcData.NpcBlip = AddBlipForCoord(sharedConfig.npcLocations.locations[route].x, sharedConfig.npcLocations.locations[route].y, sharedConfig.npcLocations.locations[route].z)
        SetBlipColour(NpcData.NpcBlip, 3)
        SetBlipRoute(NpcData.NpcBlip, true)
        SetBlipRouteColour(NpcData.NpcBlip, 3)
        NpcData.LastNpc = route
        NpcData.Active = true
        local inRange = false
        local shownTextUI = false
        pickupZone = lib.zones.sphere({
            name = "qbx_busjob_bus_pickup",
            coords = vec3(sharedConfig.npcLocations.locations[route].x, sharedConfig.npcLocations.locations[route].y, sharedConfig.npcLocations.locations[route].z),
            radius = 5,
            debug = config.debugPoly,
            onEnter = function()
                inRange = true
                if not shownTextUI then
                    lib.showTextUI(locale('info.busstop_text'))
                    shownTextUI = true
                end
                CreateThread(function()
                    repeat
                        Wait(0)
                        if IsControlJustPressed(0, 38) then
                            local maxSeats, freeSeat = GetVehicleModelNumberOfSeats(GetEntityModel(cache.vehicle))

                            for i = maxSeats - 1, 0, -1 do
                                if IsVehicleSeatFree(cache.vehicle, i) then
                                    freeSeat = i
                                    break
                                end
                            end

                            if not freeSeat then return end

                            ClearPedTasksImmediately(NpcData.Npc)
                            FreezeEntityPosition(NpcData.Npc, false)
                            TaskEnterVehicle(NpcData.Npc, cache.vehicle, -1, freeSeat, 1.0, 0)
                            Wait(3000)
                            lib.notify({
                                title = locale('info.bus_job'),
                                description = locale('info.goto_busstop'),
                                type = 'info'
                            })
                            removeNPCBlip()
                            getDeliveryLocation()
                            NpcData.NpcTaken = true
                            lib.hideTextUI()
                            shownTextUI = false
                            pickupZone:remove()
                            pickupZone = nil
                            break
                        end
                    until not inRange
                end)
            end,
            onExit = function()
                lib.hideTextUI()
                shownTextUI = false
                inRange = false
            end
        })
    else
        lib.notify({
            title = locale('info.bus_job'),
            description = locale('error.already_driving_bus'),
            type = 'info'
        })
    end
end)
