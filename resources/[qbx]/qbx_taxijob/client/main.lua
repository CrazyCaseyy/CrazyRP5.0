-- Variables
local config = require 'config.client'
local sharedConfig = require 'config.shared'
local isLoggedIn = LocalPlayer.state.isLoggedIn
local meterIsOpen = false
local meterActive = false
local lastLocation = nil
local mouseActive = false
local taxiParkingZone = nil
local pickupLocation, dropOffLocation = nil, nil

-- used for polyzones
local isInsidePickupZone = false
local isInsideDropZone = false

local meterData = {
    fareAmount = 6,
    currentFare = 0,
    distanceTraveled = 0
}

local NpcData = {
    Active = false,
    CurrentNpc = nil,
    LastNpc = nil,
    CurrentDeliver = nil,
    LastDeliver = nil,
    Npc = nil,
    NpcBlip = nil,
    DeliveryBlip = nil,
    NpcTaken = false,
    NpcDelivered = false,
    CountDown = 180
}

local taxiPed = nil

local function resetNpcTask()
    NpcData = {
        Active = false,
        CurrentNpc = nil,
        LastNpc = nil,
        CurrentDeliver = nil,
        LastDeliver = nil,
        Npc = nil,
        NpcBlip = nil,
        DeliveryBlip = nil,
        NpcTaken = false,
        NpcDelivered = false
    }
end

local function resetMeter()
    meterData = {
        fareAmount = 6,
        currentFare = 0,
        distanceTraveled = 0
    }
end

local function whitelistedVehicle()
    local veh = GetEntityModel(cache.vehicle)
    local retval = false

    for i = 1, #config.allowedVehicles, 1 do
        if veh == joaat(config.allowedVehicles[i].model) then
            retval = true
        end
    end

    if veh == `dynasty` then
        retval = true
    end

    return retval
end

local function isDriver()
    return cache.seat == -1
end

local zone
local delieveryZone

local function getDeliveryLocation()
    NpcData.CurrentDeliver = math.random(1, #sharedConfig.npcLocations.deliverLocations)
    if NpcData.LastDeliver then
        while NpcData.LastDeliver == NpcData.CurrentDeliver do
            NpcData.CurrentDeliver = math.random(1, #sharedConfig.npcLocations.deliverLocations)
        end
    end

    if NpcData.DeliveryBlip then
        RemoveBlip(NpcData.DeliveryBlip)
    end
    NpcData.DeliveryBlip = AddBlipForCoord(sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].x, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].y, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].z)
    SetBlipColour(NpcData.DeliveryBlip, 3)
    SetBlipRoute(NpcData.DeliveryBlip, true)
    SetBlipRouteColour(NpcData.DeliveryBlip, 3)
    NpcData.LastDeliver = NpcData.CurrentDeliver
    if not config.useTarget then -- added checks to disable distance checking if polyzone option is used
        CreateThread(function()
            while true do
                local pos = GetEntityCoords(cache.ped)
                local dist = #(pos - vec3(sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].x, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].y, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].z))
                if dist < 20 then
                    DrawMarker(2, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].x, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].y, sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 255, 255, false, false, 0, true, nil, nil, false)
                    if dist < 5 then
                        qbx.drawText3d({text = locale('info.drop_off_npc'), coords = sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver].xyz})
                        if IsControlJustPressed(0, 38) then
                            TaskLeaveVehicle(NpcData.Npc, cache.vehicle, 0)
                            SetEntityAsMissionEntity(NpcData.Npc, false, true)
                            SetEntityAsNoLongerNeeded(NpcData.Npc)
                            local targetCoords = sharedConfig.npcLocations.takeLocations[NpcData.LastNpc]
                            TaskGoStraightToCoord(NpcData.Npc, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
                            SendNUIMessage({
                                action = 'toggleMeter'
                            })
                            TriggerServerEvent('qb-taxi:server:NpcPay', meterData.currentFare)
                            meterActive = false
                            SendNUIMessage({
                                action = 'resetMeter'
                            })

                            pickupLocation, dropOffLocation = nil, nil

                            exports.qbx_core:Notify(locale('info.person_was_dropped_off'), 'success')
                            if NpcData.DeliveryBlip then
                                RemoveBlip(NpcData.DeliveryBlip)
                            end
                            local RemovePed = function(p)
                                SetTimeout(60000, function()
                                    DeletePed(p)
                                end)
                            end
                            RemovePed(NpcData.Npc)
                            resetNpcTask()
                            break
                        end
                    end
                end
                Wait(0)
            end
        end)
    end
end

local function callNpcPoly()
    CreateThread(function()
        while not NpcData.NpcTaken do
            if isInsidePickupZone then
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    local veh = cache.vehicle
                    local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(veh), 0

                    for i= maxSeats - 1, 0, -1 do
                        if IsVehicleSeatFree(veh, i) then
                            freeSeat = i
                            break
                        end
                    end

                    meterIsOpen = true
                    meterActive = true

                    lastLocation = GetEntityCoords(cache.ped)
                    SendNUIMessage({
                        action = 'openMeter',
                        toggle = true,
                        meterData = config.meter
                    })
                    SendNUIMessage({
                        action = 'toggleMeter'
                    })
                    pickupLocation = GetEntityCoords(cache.ped)
                    ClearPedTasksImmediately(NpcData.Npc)
                    FreezeEntityPosition(NpcData.Npc, false)
                    TaskEnterVehicle(NpcData.Npc, veh, -1, freeSeat, 1.0, 0)
                    exports.qbx_core:Notify(locale('info.go_to_location'), 'inform')
                    if NpcData.NpcBlip then
                        RemoveBlip(NpcData.NpcBlip)
                    end
                    getDeliveryLocation()
                    NpcData.NpcTaken = true
                    createNpcDelieveryLocation()
                    zone:remove()
                    lib.hideTextUI()
                end
            end
            Wait(0)
        end
    end)
end

local function onEnterCallZone()
    if whitelistedVehicle() and not isInsidePickupZone and not NpcData.NpcTaken then
        isInsidePickupZone = true
        lib.showTextUI(locale('info.call_npc'), {position = 'left-center'})
        callNpcPoly()
    end
end

local function onExitCallZone()
    lib.hideTextUI()
    isInsidePickupZone = false
end

local function createNpcPickUpLocation()
    zone = lib.zones.box({
        coords = config.pzLocations.takeLocations[NpcData.CurrentNpc].coord,
        size = vec3(config.pzLocations.takeLocations[NpcData.CurrentNpc].height, config.pzLocations.takeLocations[NpcData.CurrentNpc].width, (config.pzLocations.takeLocations[NpcData.CurrentNpc].maxZ - config.pzLocations.takeLocations[NpcData.CurrentNpc].minZ)),
        rotation = config.pzLocations.takeLocations[NpcData.CurrentNpc].heading,
        debug = config.debugPoly,
        onEnter = onEnterCallZone,
        onExit = onExitCallZone
    })
end



local function enumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
	local nearbyEntities = {}
	if coords then
		coords = vec3(coords.x, coords.y, coords.z)
	else
		coords = GetEntityCoords(cache.ped)
	end
	for k, entity in pairs(entities) do
		local distance = #(coords - GetEntityCoords(entity))
		if distance <= maxDistance then
			nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
		end
	end
	return nearbyEntities
end

local function getVehiclesInArea(coords, maxDistance) -- Vehicle inspection in designated area
	return enumerateEntitiesWithinDistance(GetGamePool('CVehicle'), false, coords, maxDistance)
end

local function isSpawnPointClear(coords, maxDistance)
	return #getVehiclesInArea(coords, maxDistance) == 0
end

local function getVehicleSpawnPoint()
	local clearSpots = {}
	for k, v in pairs(config.cabSpawns) do
		if isSpawnPointClear(vec3(v.x, v.y, v.z), 1.0) then
			clearSpots[#clearSpots + 1] = k
		end
	end
	if #clearSpots == 0 then return nil end
	return clearSpots[math.random(1, #clearSpots)]
end

local function calculateFareAmount()
    if meterIsOpen and meterActive then
        local startPos = lastLocation
        local newPos = GetEntityCoords(cache.ped)
        if startPos ~= newPos then
            local newDistance = #(startPos - newPos)
            lastLocation = newPos

            meterData['distanceTraveled'] += (newDistance / 1609)

            local fareAmount = 0

            if config.meter.useGpsPrice and pickupLocation and dropOffLocation then
                local totalRouteDistance = CalculateTravelDistanceBetweenPoints(pickupLocation.x, pickupLocation.y, pickupLocation.z, dropOffLocation.x, dropOffLocation.y, dropOffLocation.z) / 1609
                local progress = math.min(meterData['distanceTraveled'] / totalRouteDistance, 1.0)
                fareAmount = (totalRouteDistance * progress * config.meter.defaultPrice) + config.meter.startingPrice
            else
                fareAmount = (meterData['distanceTraveled'] * config.meter.defaultPrice) + config.meter.startingPrice
            end

            meterData['currentFare'] = math.floor(fareAmount)


            SendNUIMessage({
                action = 'updateMeter',
                meterData = meterData
            })
        end
    end
end

local function onEnterDropZone()
    if whitelistedVehicle() and not isInsideDropZone and NpcData.NpcTaken then
        isInsideDropZone = true
        lib.showTextUI(locale('info.drop_off_npc'), {position = 'left-center'})
        dropNpcPoly()
    end
end

local function onExitDropZone()
    lib.hideTextUI()
    isInsideDropZone = false

end

function createNpcDelieveryLocation()
    delieveryZone = lib.zones.box({
        coords = config.pzLocations.dropLocations[NpcData.CurrentDeliver].coord,
        size = vec3(config.pzLocations.dropLocations[NpcData.CurrentDeliver].height, config.pzLocations.dropLocations[NpcData.CurrentDeliver].width, (config.pzLocations.dropLocations[NpcData.CurrentDeliver].maxZ - config.pzLocations.dropLocations[NpcData.CurrentDeliver].minZ)),
        rotation = config.pzLocations.dropLocations[NpcData.CurrentDeliver].heading,
        debug = config.debugPoly,
        onEnter = onEnterDropZone,
        onExit = onExitDropZone
    })
end

function dropNpcPoly()
    CreateThread(function()
        while NpcData.NpcTaken do
            if isInsideDropZone then
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    local veh = cache.vehicle
                    TaskLeaveVehicle(NpcData.Npc, veh, 0)
                    Wait(1000)
                    SetVehicleDoorShut(veh, 3, false)
                    SetEntityAsMissionEntity(NpcData.Npc, false, true)
                    SetEntityAsNoLongerNeeded(NpcData.Npc)
                    local targetCoords = sharedConfig.npcLocations.takeLocations[NpcData.LastNpc]
                    TaskGoStraightToCoord(NpcData.Npc, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
                    SendNUIMessage({
                        action = 'toggleMeter'
                    })
                    TriggerServerEvent('qb-taxi:server:NpcPay', meterData.currentFare)
                    meterActive = false
                    SendNUIMessage({
                        action = 'resetMeter'
                    })
                    exports.qbx_core:Notify(locale('info.person_was_dropped_off'), 'success')
                    if NpcData.DeliveryBlip ~= nil then
                        RemoveBlip(NpcData.DeliveryBlip)
                    end
                    local RemovePed = function(p)
                        SetTimeout(60000, function()
                            DeletePed(p)
                        end)
                    end
                    RemovePed(NpcData.Npc)
                    resetNpcTask()
                    delieveryZone:remove()
                    lib.hideTextUI()
                    break
                end
            end
            Wait(0)
        end
    end)
end

local function setLocationsBlip()
    if not config.useBlips then return end
    local taxiBlip = AddBlipForCoord(config.locations.main.coords.x, config.locations.main.coords.y, config.locations.main.coords.z)
    SetBlipSprite(taxiBlip, 198)
    SetBlipDisplay(taxiBlip, 4)
    SetBlipScale(taxiBlip, 0.6)
    SetBlipAsShortRange(taxiBlip, true)
    SetBlipColour(taxiBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(locale('info.blip_name'))
    EndTextCommandSetBlipName(taxiBlip)
end

-- Only one allowed vehicle model exists (the taxi itself), so interacting
-- with the ped hands it straight out - no vehicle-choice menu needed.
local pedSpawned = false

local function SpawnPed()
    if pedSpawned then return end
    pedSpawned = true

    local model = joaat(config.ped.model)
    local ok = pcall(lib.requestModel, model, 10000)
    if not ok or not HasModelLoaded(model) then
        print(('^1[qbx_taxijob]^7 failed to load ped model %s - clipboard ped was not spawned'):format(config.ped.model))
        pedSpawned = false
        return
    end

    local coords = config.ped.coords
    taxiPed = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not taxiPed or taxiPed == 0 then
        print('^1[qbx_taxijob]^7 CreatePed returned an invalid entity - clipboard ped was not spawned')
        pedSpawned = false
        return
    end

    SetPedDefaultComponentVariation(taxiPed)
    FreezeEntityPosition(taxiPed, true)
    SetEntityInvincible(taxiPed, true)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
    TaskStartScenarioInPlace(taxiPed, config.ped.scenario, 0, true)

    -- No 'job' filter - anyone can interact, not just the taxi job.
    exports.ox_target:addLocalEntity(taxiPed, {
        {
            name = 'qbx_taxijob_start',
            icon = 'fa-solid fa-taxi',
            label = locale('info.request_taxi_target'),
            distance = 1.5,
            onSelect = function()
                TriggerEvent('qb-taxi:client:TakeVehicle', { model = config.allowedVehicles[1].model })
            end,
        }
    })
end

function setupTaxiParkingZone()
        taxiParkingZone = lib.zones.box({
        coords = vec3(config.locations.main.coords.x, config.locations.main.coords.y, config.locations.main.coords.z),
        size = vec3(4.0, 4.0, 4.0),
        rotation = 55,
        debug = config.debugPoly,
        inside = function()
            -- No longer requires the taxi job - anyone can return the cab.
            if IsControlJustPressed(0, 38) then
                if whitelistedVehicle() then
                    if meterIsOpen then
                        TriggerEvent('qb-taxi:client:toggleMeter')
                        meterActive = false
                    end
                    DeleteVehicle(cache.vehicle)
                    exports.qbx_core:Notify(locale('info.taxi_returned'), 'success')
                end
            end
        end,
        onEnter = function()
            lib.showTextUI(locale('info.vehicle_parking'), { position = 'right-center' })
        end,
        onExit = function()
            lib.hideTextUI()
        end
    })
end

-- Red circle at the return zone so it's visible from a bit of a
-- distance, not just once already standing in the (small) return box.
CreateThread(function()
    local hubCoords = config.locations.main.coords
    while true do
        if #(GetEntityCoords(cache.ped) - hubCoords.xyz) < 30.0 then
            DrawMarker(2, hubCoords.x, hubCoords.y, hubCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, 0, true, false, false, false)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function destroyTaxiParkingZone()
    if not taxiParkingZone then return end

    taxiParkingZone:remove()
    taxiParkingZone = nil
end

RegisterNetEvent('qb-taxi:client:TakeVehicle', function(data)
    local SpawnPoint = getVehicleSpawnPoint()
    if SpawnPoint then
        local coords = config.cabSpawns[SpawnPoint]
        local CanSpawn = isSpawnPointClear(coords, 1.0)
        if CanSpawn then
            local netId = lib.callback.await('qb-taxi:server:spawnTaxi', false, data.model, coords)
            if not netId then
                exports.qbx_core:Notify(locale('info.no_spawn_point'), 'error')
                return
            end
            local veh = NetToVeh(netId)
            SetVehicleFuelLevel(veh, 100.0)
            SetVehicleEngineOn(veh, true, true, false)
        else
            exports.qbx_core:Notify(locale('info.no_spawn_point'), 'error')
        end
    else
        exports.qbx_core:Notify(locale('info.no_spawn_point'), 'error')
        return
    end
end)

-- Events
RegisterNetEvent('qb-taxi:client:DoTaxiNpc', function()
    if whitelistedVehicle() then
        if not NpcData.Active then
            NpcData.CurrentNpc = math.random(1, #sharedConfig.npcLocations.takeLocations)
            if NpcData.LastNpc ~= nil then
                while NpcData.LastNpc == NpcData.CurrentNpc do
                    NpcData.CurrentNpc = math.random(1, #sharedConfig.npcLocations.takeLocations)
                end
            end

            local Gender = math.random(1, #config.npcSkins)
            local PedSkin = math.random(1, #config.npcSkins[Gender])
            local model = GetHashKey(config.npcSkins[Gender][PedSkin])
            lib.requestModel(model)
            NpcData.Npc = CreatePed(3, model, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].x, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].y, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].z - 0.98, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].w, true, true)
            SetModelAsNoLongerNeeded(model)
            PlaceObjectOnGroundProperly(NpcData.Npc)
            FreezeEntityPosition(NpcData.Npc, true)
            if NpcData.NpcBlip ~= nil then
                RemoveBlip(NpcData.NpcBlip)
            end
            exports.qbx_core:Notify(locale('info.npc_on_gps'), 'success')

            -- added checks to disable distance checking if polyzone option is used
            if config.useTarget then
                createNpcPickUpLocation()
            end

            NpcData.NpcBlip = AddBlipForCoord(sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].x, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].y, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].z)
            SetBlipColour(NpcData.NpcBlip, 3)
            SetBlipRoute(NpcData.NpcBlip, true)
            SetBlipRouteColour(NpcData.NpcBlip, 3)
            NpcData.LastNpc = NpcData.CurrentNpc
            NpcData.Active = true

            -- added checks to disable distance checking if polyzone option is used
            if not config.useTarget then
                CreateThread(function()
                    while not NpcData.NpcTaken do

                        local pos = GetEntityCoords(cache.ped)
                        local dist = #(pos - vec3(sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].x, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].y, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].z))

                        if dist < 20 then
                            DrawMarker(2, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].x, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].y, sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 255, 255, false, false, 0, true, nil, nil, false)

                            if dist < 5 then
                                qbx.drawText3d({text = locale('info.call_npc'), coords = sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc].xyz})
                                if IsControlJustPressed(0, 38) then
                                    local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(cache.vehicle), 0

                                    for i=maxSeats - 1, 0, -1 do
                                        if IsVehicleSeatFree(cache.vehicle, i) then
                                            freeSeat = i
                                            break
                                        end
                                    end

                                    pickupLocation = GetEntityCoords(cache.ped)

                                    meterIsOpen = true
                                    meterActive = true
                                    lastLocation = GetEntityCoords(cache.ped)
                                    SendNUIMessage({
                                        action = 'openMeter',
                                        toggle = true,
                                        meterData = config.meter
                                    })
                                    SendNUIMessage({
                                        action = 'toggleMeter'
                                    })
                                    ClearPedTasksImmediately(NpcData.Npc)
                                    FreezeEntityPosition(NpcData.Npc, false)
                                    TaskEnterVehicle(NpcData.Npc, cache.vehicle, -1, freeSeat, 1.0, 0)
                                    exports.qbx_core:Notify(locale('info.go_to_location'), 'inform')
                                    if NpcData.NpcBlip ~= nil then
                                        RemoveBlip(NpcData.NpcBlip)
                                    end
                                    getDeliveryLocation()
                                    dropOffLocation = config.pzLocations.dropLocations[NpcData.CurrentDeliver].coord.xyz
                                    NpcData.NpcTaken = true
                                end
                            end
                        end

                        Wait(0)
                    end
                end)
            end
        else
            exports.qbx_core:Notify(locale('error.already_mission'), 'error')
        end
    else
        exports.qbx_core:Notify(locale('error.not_in_taxi'), 'error')
    end
end)

RegisterNetEvent('qb-taxi:client:toggleMeter', function()
    if cache.vehicle then
        if whitelistedVehicle() then
            if not meterIsOpen and isDriver() then
                SendNUIMessage({
                    action = 'openMeter',
                    toggle = true,
                    meterData = config.meter
                })
                meterIsOpen = true
            else
                SendNUIMessage({
                    action = 'openMeter',
                    toggle = false
                })
                meterIsOpen = false
            end
        else
            exports.qbx_core:Notify(locale('error.missing_meter'), 'error')
        end
    else
        exports.qbx_core:Notify(locale('error.no_vehicle'), 'error')
    end
end)

RegisterNetEvent('qb-taxi:client:enableMeter', function()
    if meterIsOpen then
        SendNUIMessage({
            action = 'toggleMeter'
        })
    else
        exports.qbx_core:Notify(locale('error.not_active_meter'), 'error')
    end
end)

RegisterNetEvent('qb-taxi:client:toggleMuis', function()
    Wait(400)
    if meterIsOpen then
        if not mouseActive then
            SetNuiFocus(true, true)
            mouseActive = true
        end
    else
        exports.qbx_core:Notify(locale('error.no_meter_sight'), 'error')
    end
end)

-- NUI Callbacks
RegisterNUICallback('enableMeter', function(data, cb)
    meterActive = data.enabled
    if not meterActive then resetMeter() end
    lastLocation = GetEntityCoords(cache.ped)
    cb('ok')
end)

RegisterNUICallback('hideMouse', function(_, cb)
    SetNuiFocus(false, false)
    mouseActive = false
    cb('ok')
end)

-- Threads
CreateThread(function()
    while true do
        Wait(2000)
        calculateFareAmount()
    end
end)

CreateThread(function()
    while true do
        if not cache.vehicle then
            if meterIsOpen then
                SendNUIMessage({
                    action = 'openMeter',
                    toggle = false
                })
                meterIsOpen = false
            end
        end
        Wait(200)
    end
end)

-- No longer requires the taxi job - anyone can use the taxi ped/zone/blip.
-- These only need setting up once each, not torn down and rebuilt on
-- every job change any more.
local function init()
    SpawnPed()
    if not taxiParkingZone then setupTaxiParkingZone() end
    setLocationsBlip()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    init()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

-- Covers a client that's already loaded in by the time this resource
-- (re)starts - e.g. a manual `restart qbx_taxijob` - since
-- OnPlayerLoaded won't fire again for them on its own.
if isLoggedIn then
    init()
end