local config = require 'config.client'
local sharedConfig = require 'config.shared'
local playerJob
local garbageVehicle
local hasBag = false
local currentStop = 0
local deliveryBlip
local amountOfBags = 0
local garbageObject
local endBlip
local garbageBlip
local canTakeBag = true
local currentStopNum = 0
local pZone
local garbageBinZone
local finished = false
local continueWorking = false
local garbText = false
local trucText = false
local pedsSpawned = false

-- Group lobby state - nil/false/{} whenever working solo (the default).
local currentLobbyId = nil
local lobbyMembers = {}
local lobbyIsLeader = false
local lobbyStarted = false

-- Forward declarations - these all reference each other (menu -> dialog ->
-- server -> menu again), so they're assigned as plain functions further
-- down rather than nested local functions.
local applyLobbySnapshot
local openLobbyMenu
local createGroup
local openJoinGroupMenu
local attemptJoin
local openSetCutsDialog
local beginLobbyShift
local handleBagDelivered
local SetRouteBack

local function setupClient()
    garbageVehicle = nil
    hasBag = false
    currentStop = 0
    deliveryBlip = nil
    amountOfBags = 0
    garbageObject = nil
    endBlip = nil
    currentStopNum = 0
    -- No longer requires the garbage job - anyone can pick up shifts.
    garbageBlip = AddBlipForCoord(sharedConfig.locations.main.coords.x, sharedConfig.locations.main.coords.y, sharedConfig.locations.main.coords.z)
    SetBlipSprite(garbageBlip, 318)
    SetBlipDisplay(garbageBlip, 4)
    SetBlipScale(garbageBlip, 1.0)
    SetBlipAsShortRange(garbageBlip, true)
    SetBlipColour(garbageBlip, 39)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(sharedConfig.locations.main.label)
    EndTextCommandSetBlipName(garbageBlip)
end

local function garbageMenu()
    if currentLobbyId then
        openLobbyMenu()
        return
    end

    local options = {}
    options[#options + 1] = {
        title = locale('menu.collect'),
        description = locale('menu.return_collect'),
        event = 'qb-garbagejob:client:RequestPaycheck'
    }
    if not garbageVehicle or finished then
        options[#options + 1] = {
            title = locale('menu.route'),
            description = locale('menu.request_route'),
            event = 'qb-garbagejob:client:RequestRoute'
        }
        options[#options + 1] = {
            title = locale('menu.create_group'),
            description = locale('menu.create_group_desc'),
            icon = 'user-group',
            onSelect = createGroup,
        }
        options[#options + 1] = {
            title = locale('menu.join_group'),
            description = locale('menu.join_group_desc'),
            icon = 'right-to-bracket',
            arrow = true,
            onSelect = openJoinGroupMenu,
        }
    end
    lib.registerContext({
        id = 'qb_gargabejob_mainMenu',
        title = locale('menu.header'),
        options = options
    })

    lib.showContext('qb_gargabejob_mainMenu')
end

-- ===================================================================
-- Group lobbies
-- ===================================================================

applyLobbySnapshot = function(snapshot)
    if not snapshot then
        currentLobbyId = nil
        lobbyMembers = {}
        lobbyIsLeader = false
        lobbyStarted = false
        return
    end

    currentLobbyId = snapshot.id
    lobbyMembers = snapshot.members
    lobbyIsLeader = snapshot.leaderCid == QBX.PlayerData.citizenid
    lobbyStarted = snapshot.started
end

openSetCutsDialog = function()
    local rows = {}
    local order = {}
    for _, m in ipairs(lobbyMembers) do
        rows[#rows + 1] = {
            type = 'number',
            label = m.name,
            description = locale('menu.cut_percent'),
            default = math.floor(m.cut + 0.5),
            min = 0,
            max = 100,
        }
        order[#order + 1] = m.citizenid
    end

    local input = lib.inputDialog(locale('menu.lobby_setcuts'), rows)
    if not input then return end

    local cuts = {}
    for i, cid in ipairs(order) do
        cuts[cid] = tonumber(input[i]) or 0
    end

    local result = lib.callback.await('garbagejob:server:setCuts', false, cuts)
    if not result or result.error then
        exports.qbx_core:Notify(locale('error.lobby_cuts_failed'), 'error')
        return
    end

    applyLobbySnapshot(result.snapshot)
    exports.qbx_core:Notify(locale('info.lobby_cuts_updated'), 'success')
end

beginLobbyShift = function()
    local result = lib.callback.await('garbagejob:server:startLobbyShift', false)
    if not result or result.error then
        exports.qbx_core:Notify(locale('error.lobby_start_failed'), 'error')
        return
    end

    lobbyStarted = true

    -- Same spawn-point search solo uses (garbagejob:server:spawnVehicle
    -- already charges the truck deposit - shared out again for everyone
    -- at payout, same as solo's own deposit refund).
    local occupied = false
    for _, v in pairs(sharedConfig.locations.vehicle.coords) do
        if not IsAnyVehicleNearPoint(v.x, v.y, v.z, 2.5) then
            local netId = lib.callback.await('garbagejob:server:spawnVehicle', false, v)
            local veh = lib.waitFor(function()
                if NetworkDoesEntityExistWithNetworkId(netId) then
                    return NetToVeh(netId)
                end
            end, 'Failed to spawn truck', 3000)

            if veh == 0 then
                exports.qbx_core:Notify('Failed to spawn truck', 'error')
                return
            end

            garbageVehicle = veh
            SetVehicleFuelLevel(veh, 100.0)
            SetVehicleFixed(veh)
            currentStop = result.firstStop
            currentStopNum = 1
            amountOfBags = result.totalBags
            SetGarbageRoute()

            TriggerServerEvent('garbagejob:server:setLobbyVehicle', currentLobbyId, netId)
            exports.qbx_core:Notify(locale('info.started'), 'success')
            return
        else
            occupied = true
        end
    end
    if occupied then
        exports.qbx_core:Notify(locale('error.all_occupied'), 'error')
    end
end

openLobbyMenu = function()
    local options = {}

    if lobbyStarted then
        options[#options + 1] = {
            title = locale('menu.collect'),
            description = locale('menu.return_collect'),
            icon = 'sack-dollar',
            onSelect = function()
                TriggerServerEvent('garbagejob:server:payLobbyShift', currentLobbyId)
            end,
        }
    elseif lobbyIsLeader then
        options[#options + 1] = {
            title = locale('menu.lobby_start'),
            description = locale('menu.lobby_start_desc'),
            icon = 'play',
            onSelect = beginLobbyShift,
        }
        options[#options + 1] = {
            title = locale('menu.lobby_setcuts'),
            description = locale('menu.lobby_setcuts_desc'),
            icon = 'percent',
            onSelect = openSetCutsDialog,
        }
    end

    for _, m in ipairs(lobbyMembers) do
        options[#options + 1] = {
            title = m.isLeader and locale('menu.member_leader', m.name) or m.name,
            description = locale('menu.member_cut', math.floor(m.cut + 0.5)),
            icon = 'user',
            disabled = true,
        }
    end

    options[#options + 1] = {
        title = locale('menu.lobby_leave'),
        icon = 'right-from-bracket',
        onSelect = function()
            TriggerServerEvent('garbagejob:server:leaveLobby')
            applyLobbySnapshot(nil)
        end,
    }

    lib.registerContext({
        id = 'qb_garbagejob_lobbyMenu',
        title = locale('menu.lobby_header'),
        options = options,
    })
    lib.showContext('qb_garbagejob_lobbyMenu')
end

createGroup = function()
    local input = lib.inputDialog(locale('menu.create_group'), {
        {
            type = 'input',
            label = locale('menu.passcode_label'),
            description = locale('menu.passcode_optional'),
            required = false,
        },
    })
    if not input then return end

    local result = lib.callback.await('garbagejob:server:createLobby', false, input[1] or '')
    if not result or result.error then
        exports.qbx_core:Notify(locale('error.lobby_create_failed'), 'error')
        return
    end

    applyLobbySnapshot(result.snapshot)
    exports.qbx_core:Notify(locale('info.lobby_created'), 'success')
    openLobbyMenu()
end

attemptJoin = function(lobbyId, hasPasscode)
    local passcode = ''
    if hasPasscode then
        local input = lib.inputDialog(locale('menu.enter_passcode'), {
            { type = 'input', label = locale('menu.passcode_label'), required = true },
        })
        if not input then return end
        passcode = input[1]
    end

    local result = lib.callback.await('garbagejob:server:joinLobby', false, lobbyId, passcode)
    if not result or result.error then
        exports.qbx_core:Notify(locale('error.lobby_join_failed'), 'error')
        return
    end

    applyLobbySnapshot(result.snapshot)
    exports.qbx_core:Notify(locale('info.lobby_joined'), 'success')
    openLobbyMenu()
end

openJoinGroupMenu = function()
    local list = lib.callback.await('garbagejob:server:listLobbies', false)
    local options = {}
    if list then
        for _, l in ipairs(list) do
            options[#options + 1] = {
                title = locale('menu.lobby_entry', l.leaderName),
                description = locale('menu.lobby_entry_desc', l.memberCount) .. (l.hasPasscode and (' - ' .. locale('menu.locked')) or ''),
                icon = l.hasPasscode and 'lock' or 'users',
                onSelect = function() attemptJoin(l.id, l.hasPasscode) end,
            }
        end
    end
    if #options == 0 then
        options[1] = { title = locale('menu.no_lobbies'), disabled = true }
    end

    lib.registerContext({
        id = 'qb_garbagejob_joinMenu',
        title = locale('menu.join_group'),
        menu = 'qb_gargabejob_mainMenu',
        options = options,
    })
    lib.showContext('qb_garbagejob_joinMenu')
end

-- Returns true once the stop is cleared (route advanced or finished - in
-- lobby mode that's handled uniformly for every member via the
-- lobbyStopAdvanced broadcast, not here), false if there are still bags
-- left at this stop, or nil on error.
handleBagDelivered = function(pos)
    if currentLobbyId then
        local result = lib.callback.await('garbagejob:server:lobbyDeliverBag', false, currentLobbyId, pos)
        if not result or result.error then
            exports.qbx_core:Notify(locale('error.too_far'), 'error')
            return nil
        end
        if not result.cleared then
            amountOfBags = result.bagsLeft
            if amountOfBags > 1 then
                exports.qbx_core:Notify(locale('info.bags_left', amountOfBags))
            else
                exports.qbx_core:Notify(locale('info.bags_still', amountOfBags))
            end
            return false
        end
        return true
    end

    -- Solo - unchanged from before.
    if (amountOfBags - 1) <= 0 then
        local hasMoreStops, nextStop, newBagAmount = lib.callback.await('garbagejob:server:nextStop', false, currentStop, currentStopNum, pos)
        if hasMoreStops and nextStop ~= 0 then
            currentStop = nextStop
            currentStopNum = currentStopNum + 1
            amountOfBags = newBagAmount
            SetGarbageRoute()
            exports.qbx_core:Notify(locale('info.all_bags'))
            SetVehicleDoorShut(garbageVehicle, 5, false)
        elseif hasMoreStops and nextStop == currentStop then
            exports.qbx_core:Notify(locale('info.depot_issue'))
            amountOfBags = 0
        else
            exports.qbx_core:Notify(locale('info.done_working'))
            SetVehicleDoorShut(garbageVehicle, 5, false)
            RemoveBlip(deliveryBlip)
            SetRouteBack()
            amountOfBags = 0
        end
        return true
    end

    amountOfBags = amountOfBags - 1
    if amountOfBags > 1 then
        exports.qbx_core:Notify(locale('info.bags_left', amountOfBags))
    else
        exports.qbx_core:Notify(locale('info.bags_still', amountOfBags))
    end
    return false
end

local function BringBackCar()
    DeleteVehicle(garbageVehicle)
    if endBlip then
        RemoveBlip(endBlip)
    end
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    garbageVehicle = nil
    hasBag = false
    currentStop = 0
    deliveryBlip = nil
    amountOfBags = 0
    garbageObject = nil
    endBlip = nil
    currentStopNum = 0
end

local function DeleteZone()
    pZone:remove()
end

SetRouteBack = function()
    local depot = sharedConfig.locations.main.coords
    endBlip = AddBlipForCoord(depot.x, depot.y, depot.z)
    SetBlipSprite(endBlip, 1)
    SetBlipDisplay(endBlip, 2)
    SetBlipScale(endBlip, 1.0)
    SetBlipAsShortRange(endBlip, false)
    SetBlipColour(endBlip, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(sharedConfig.locations.vehicle.label)
    EndTextCommandSetBlipName(endBlip)
    SetBlipRoute(endBlip, true)
    DeleteZone()
    finished = true
end

local function AnimCheck()
    CreateThread(function()
        while hasBag and not IsEntityPlayingAnim(cache.ped, 'missfbi4prepp1', '_bag_throw_garbage_man',3) do
            if not IsEntityPlayingAnim(cache.ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 3) then
                ClearPedTasksImmediately(cache.ped)
                lib.playAnim(cache.ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 6.0, -6.0, -1, 49, 0, false, false, false)
            end
            Wait(1000)
        end
    end)
end

local function DeliverAnim()
    lib.playAnim(cache.ped, 'missfbi4prepp1', '_bag_throw_garbage_man', 8.0, 8.0, 1100, 48, 0.0, false, false, false)
    FreezeEntityPosition(cache.ped, true)
    SetEntityHeading(cache.ped, GetEntityHeading(garbageVehicle))
    canTakeBag = false
    SetTimeout(1250, function()
        DetachEntity(garbageObject, true, false)
        DeleteObject(garbageObject)
        lib.playAnim(cache.ped, 'missfbi4prepp1', 'exit', 8.0, 8.0, 1100, 48, 0.0, false, false, false)
        FreezeEntityPosition(cache.ped, false)
        garbageObject = nil
        canTakeBag = true
    end)
    if config.useTarget and hasBag then
        local CL = sharedConfig.locations.trashcan[currentStop]
        hasBag = false
        local pos = GetEntityCoords(cache.ped)
        exports.ox_target:removeEntity(NetworkGetNetworkIdFromEntity(garbageVehicle), 'garbage_deliver')
        local cleared = handleBagDelivered(pos)
        if cleared == false then
            -- Still bags left at this stop - let them grab another.
            garbageBinZone = exports.ox_target:addSphereZone({
                coords = vec3(CL.coords.x, CL.coords.y, CL.coords.z),
                radius = 2.0,
                debug = config.debugPoly,
                options = {
                    {
                        label = locale('target.grab_garbage'),
                        icon = 'fa-solid fa-trash',
                        onSelect = TakeAnim,
                        distance = 2.0,
                        canInteract = function()
                            return not hasBag
                        end,
                    },
                },
            })
        end
    end
end

function TakeAnim()
    if lib.progressBar({
            duration = math.random(3000, 5000),
            label = locale('info.picking_bag'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
                mouse = false
            },
            anim = {
                dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                clip = 'machinic_loop_mechandplayer'
            }
        }) then
        lib.playAnim(cache.ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 6.0, -6.0, -1, 49, 0, false, false, false)
        lib.requestModel(`prop_cs_rub_binbag_01`, 10000)
        garbageObject = CreateObject(`prop_cs_rub_binbag_01`, 0, 0, 0, true, true, true)
        SetModelAsNoLongerNeeded(`prop_cs_rub_binbag_01`)
        AttachEntityToEntity(garbageObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.12, 0.0, -0.05, 220.0, 120.0, 0.0, true, true, false, true, 1, true)
        StopAnimTask(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)
        AnimCheck()
        if config.useTarget and not hasBag then
            hasBag = true
            if garbageBinZone then
                exports.ox_target:removeZone(garbageBinZone)
                garbageBinZone = nil
            end
            local options = {
                {
                    name = 'garbage_deliver',
                    label = locale('target.dispose_garbage'),
                    icon = 'fa-solid fa-truck',
                    onSelect = DeliverAnim,
                    canInteract = function()
                        return hasBag
                    end,
                },
            }
            exports.ox_target:addEntity(NetworkGetNetworkIdFromEntity(garbageVehicle), options)
        end
    else
        StopAnimTask(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 1.0)
        exports.qbx_core:Notify(locale('error.cancel'), 'error')
    end
end

local function runWorkLoop()
    local pos = GetEntityCoords(cache.ped)
    local DeliveryData = sharedConfig.locations.trashcan[currentStop]
    local Distance = #(pos - vec3(DeliveryData.coords.x, DeliveryData.coords.y, DeliveryData.coords.z))
    if Distance < 15 or hasBag then
        if not hasBag and canTakeBag then
            if Distance < 1.5 then
                if not garbText then
                    garbText = true
                    lib.showTextUI(locale('info.grab_garbage'))
                end
                if IsControlJustPressed(0, 51) then
                    hasBag = true
                    lib.hideTextUI()
                    TakeAnim()
                end
            elseif Distance < 10 then
                if garbText then
                    garbText = false
                    lib.hideTextUI()
                end
            end
        else
            if DoesEntityExist(garbageVehicle) then
                local Coords = GetOffsetFromEntityInWorldCoords(garbageVehicle, 0.0, -4.5, 0.0)
                local TruckDist = #(pos - Coords)

                if TruckDist < 2 then
                    if not trucText then
                        trucText = true
                        lib.showTextUI(locale('info.dispose_garbage'))
                    end
                    if IsControlJustPressed(0, 51) and hasBag then
                        StopAnimTask(cache.ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 1.0)
                        DeliverAnim()
                        if lib.progressBar({
                                duration = 2000,
                                label = locale('info.progressbar'),
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    car = true,
                                    move = true,
                                    combat = true,
                                    mouse = false
                                }
                            }) then
                            hasBag = false
                            canTakeBag = false
                            DetachEntity(garbageObject, true, false)
                            DeleteObject(garbageObject)
                            FreezeEntityPosition(cache.ped, false)
                            garbageObject = nil
                            canTakeBag = true
                            handleBagDelivered(pos)
                            hasBag = false

                            Wait(1500)
                            if trucText then
                                lib.hideTextUI()
                                trucText = false
                            end
                        else
                            exports.qbx_core:Notify(locale('error.cancel'), 'error')
                        end
                    end
                end
            else
                exports.qbx_core:Notify(locale('error.no_truck'), 'error')
                hasBag = false
            end
        end
    end
end

local function CreateZone(x, y, z)
    pZone = lib.zones.sphere({
        coords = vec3(x, y, z),
        radius = 15,
        debug = config.debugPoly,
        onEnter = function()
            SetVehicleDoorOpen(garbageVehicle,5,false,false)
        end,
        inside = function()
            if not config.useTarget then
                runWorkLoop()
            end
        end,
        onExit = function()
            if not config.useTarget then
                lib.hideTextUI()
            end
            SetVehicleDoorShut(garbageVehicle, 5, false)
        end,
    })
end

function SetGarbageRoute()
    local CL = sharedConfig.locations.trashcan[currentStop]
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    deliveryBlip = AddBlipForCoord(CL.coords.x, CL.coords.y, CL.coords.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipDisplay(deliveryBlip, 2)
    SetBlipScale(deliveryBlip, 1.0)
    SetBlipAsShortRange(deliveryBlip, false)
    SetBlipColour(deliveryBlip, 27)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(sharedConfig.locations.trashcan[currentStop].name)
    EndTextCommandSetBlipName(deliveryBlip)
    SetBlipRoute(deliveryBlip, true)
    finished = false
    if config.useTarget then
        if not hasBag then
            garbageBinZone = exports.ox_target:addSphereZone({
                coords = vec3(CL.coords.x, CL.coords.y, CL.coords.z),
                radius = 2.0,
                debug = config.debugPoly,
                options = {
                    {
                        label = locale('target.grab_garbage'),
                        icon = 'fa-solid fa-trash',
                        onSelect = TakeAnim,
                        canInteract = function()
                            return not hasBag
                        end,
                        distance = 2.0,
                    },
                },
            })
        end
    end
    if pZone then
        DeleteZone()
        Wait(500)
        CreateZone(CL.coords.x, CL.coords.y, CL.coords.z)
    else
        CreateZone(CL.coords.x, CL.coords.y, CL.coords.z)
    end
end

local function spawnPeds()
    if not config.peds or not next(config.peds) or pedsSpawned then return end
    for i = 1, #config.peds do
        local current = config.peds[i]
        current.model = type(current.model) == 'string' and joaat(current.model) or current.model

        lib.requestModel(current.model, 20000)
        local ped = CreatePed(0, current.model, current.coords.x, current.coords.y, current.coords.z, current.coords.w, false, false)
        SetModelAsNoLongerNeeded(current.model)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(current.model)
        current.pedHandle = ped

        if config.useTarget then
            -- No 'groups' filter - anyone can interact, not just the
            -- garbage job.
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'garbage_ped',
                    label = locale('target.talk'),
                    icon = 'fa-solid fa-recycle',
                    onSelect = garbageMenu,
                }
            })
        else
            lib.zones.box({
                coords = vec3(current.coords.x, current.coords.y, current.coords.z+0.5),
                size = vec3(3.0, 3.0, 2.0),
                rotation = current.coords.w,
                debug = config.debugPoly,
                inside = function()
                    if IsControlJustPressed(0, 38) then
                        garbageMenu()
                    end
                end,
                onEnter = function()
                    lib.showTextUI(locale('info.talk'))
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
            })
        end
    end
    pedsSpawned = true
end

local function deletePeds()
    if not config.peds or not next(config.peds) or not pedsSpawned then return end
    for i = 1, #config.peds do
        local current = config.peds[i]
        if current.pedHandle then
            if config.useTarget then
                exports.ox_target:removeLocalEntity(current.pedHandle, 'garbage_ped')
            end
            DeletePed(current.pedHandle)
        end
    end
end

AddEventHandler('qb-garbagejob:client:RequestRoute', function()
    if currentLobbyId then return end -- group shifts start via the lobby menu instead
    if garbageVehicle then
        continueWorking = true
        TriggerServerEvent('garbagejob:server:payShift', continueWorking)
    end

    local shouldContinue, firstStop, totalBags = lib.callback.await('garbagejob:server:newShift', false, continueWorking)
    if shouldContinue then
        if not garbageVehicle then
            local occupied = false
            for _, v in pairs(sharedConfig.locations.vehicle.coords) do
                if not IsAnyVehicleNearPoint(v.x,v.y,v.z, 2.5) then
                    local netId = lib.callback.await('garbagejob:server:spawnVehicle', false, v)

                    local veh = lib.waitFor(function()
                        if NetworkDoesEntityExistWithNetworkId(netId) then
                            return NetToVeh(netId)
                        end
                    end, 'Failed to spawn truck', 3000)

                    if veh == 0 then
                        lib.notify({ description = 'Failed to spawn truck', type = 'error' })
                        return
                    end

                    garbageVehicle = veh
                    SetVehicleFuelLevel(veh, 100.0)
                    SetVehicleFixed(veh)
                    currentStop = firstStop
                    currentStopNum = 1
                    amountOfBags = totalBags
                    SetGarbageRoute()
                    exports.qbx_core:Notify(locale('info.started'))
                    return
                else
                    occupied = true
                end
            end
            if occupied then
                exports.qbx_core:Notify(locale('error.all_occupied'))
            end
        end
        currentStop = firstStop
        currentStopNum = 1
        amountOfBags = totalBags
        SetGarbageRoute()
    else
        exports.qbx_core:Notify(locale('info.not_enough', sharedConfig.truckPrice))
    end
end)

AddEventHandler('qb-garbagejob:client:RequestPaycheck', function()
    if currentLobbyId then return end -- group shifts are paid out via the lobby menu instead
    -- Returning the truck itself now happens at the red ring below, not
    -- here - this is just the payslip.
    TriggerServerEvent('garbagejob:server:payShift')
end)

-- Red ring at the truck storage spots, matching qbx_busjob/qbx_towjob/
-- qbx_taxijob exactly - only shown for a solo shift (a lobby's shared
-- truck is only ever deleted server-side, at the group payout, so no one
-- member can pull it out from under the others here).
CreateThread(function()
    local storageCoords = sharedConfig.locations["vehicle"].coords
    local promptShown = false

    while true do
        if garbageVehicle and not currentLobbyId then
            local nearestCoords, nearestDist
            for _, c in pairs(storageCoords) do
                local dist = #(GetEntityCoords(cache.ped) - c.xyz)
                if not nearestDist or dist < nearestDist then
                    nearestCoords, nearestDist = c, dist
                end
            end

            DrawMarker(1, nearestCoords.x, nearestCoords.y, nearestCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 220, 0, 0, 120, false, false, 2, false, nil, nil, false)

            if nearestDist < 3.0 then
                -- Already know exactly which vehicle this is (garbageVehicle
                -- itself), just check it's actually parked here.
                local truckNearby = DoesEntityExist(garbageVehicle) and #(GetEntityCoords(garbageVehicle) - nearestCoords.xyz) < 5.0
                if truckNearby then
                    if not promptShown then
                        lib.showTextUI(locale('info.return_vehicle'), { position = 'right-center' })
                        promptShown = true
                    end
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        promptShown = false
                        BringBackCar()
                        exports.qbx_core:Notify(locale('info.truck_returned'))
                    end
                elseif promptShown then
                    lib.hideTextUI()
                    promptShown = false
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

-- ===================================================================
-- Group lobby events
-- ===================================================================

RegisterNetEvent('garbagejob:client:lobbyUpdated', function(snapshot)
    applyLobbySnapshot(snapshot)
end)

-- Non-leader members learn the shared truck's netId here once the leader
-- spawns it.
RegisterNetEvent('garbagejob:client:lobbyVehicleReady', function(netId, firstStop, totalBags)
    if not currentLobbyId then return end

    local veh = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end, 'Failed to sync truck', 5000)
    if not veh or veh == 0 then return end

    garbageVehicle = veh
    currentStop = firstStop
    currentStopNum = 1
    amountOfBags = totalBags
    lobbyStarted = true
    SetGarbageRoute()
    exports.qbx_core:Notify(locale('info.started'), 'success')
end)

-- Fired for every member (the one who delivered included) whenever a stop
-- is cleared, so nobody's local route state can drift out of sync.
RegisterNetEvent('garbagejob:client:lobbyStopAdvanced', function(result)
    if not currentLobbyId then return end

    if result.finished then
        exports.qbx_core:Notify(locale('info.done_working'))
        if garbageVehicle then SetVehicleDoorShut(garbageVehicle, 5, false) end
        if deliveryBlip then RemoveBlip(deliveryBlip) end
        SetRouteBack()
        amountOfBags = 0
        return
    end

    currentStop = result.nextStop
    currentStopNum = currentStopNum + 1
    amountOfBags = result.newBagAmount
    SetGarbageRoute()
    exports.qbx_core:Notify(locale('info.all_bags'))
    if garbageVehicle then SetVehicleDoorShut(garbageVehicle, 5, false) end
end)

-- Fired for every member once the group payout has been paid out.
RegisterNetEvent('garbagejob:client:lobbyEnded', function()
    if garbageVehicle then
        if endBlip then RemoveBlip(endBlip) end
        if deliveryBlip then RemoveBlip(deliveryBlip) end
        garbageVehicle = nil
        hasBag = false
        currentStop = 0
        deliveryBlip = nil
        amountOfBags = 0
        garbageObject = nil
        endBlip = nil
        currentStopNum = 0
    end
    applyLobbySnapshot(nil)
    exports.qbx_core:Notify(locale('info.truck_returned'))
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerJob = QBX.PlayerData.job
    setupClient()
    spawnPeds()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    playerJob = JobInfo
    if garbageBlip then
        RemoveBlip(garbageBlip)
    end
    if endBlip then
        RemoveBlip(endBlip)
    end
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    endBlip = nil
    deliveryBlip = nil
    setupClient()
    spawnPeds()
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        if garbageObject then
            DeleteEntity(garbageObject)
            garbageObject = nil
        end
        deletePeds()
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        playerJob = QBX.PlayerData.job
        setupClient()
        spawnPeds()
    end
end)