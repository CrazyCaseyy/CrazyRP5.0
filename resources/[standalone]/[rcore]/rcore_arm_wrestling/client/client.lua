ClosestTableIndices = {}
ACTIVE_TABLE_DATA = nil
ARM_WREST_DICT = 'mini@arm_wrestling'

-- table finder
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest = {}

        for tableIdx, tableData in pairs(TABLES) do
            if #(tableData.pos - coords) < 100.0 then
                if not tableData.object then
                    if not tableData.modelHash then
                        tableData.modelHash = GetHashKey(tableData.model)
                    end

                    tableData.object = GetClosestObjectOfType(
                        tableData.pos.x, tableData.pos.y, tableData.pos.z, 
                        1.0, tableData.modelHash, false, 0, 0
                    )

                    local objCoords = GetEntityCoords(tableData.object)
                    local objHeading = GetEntityHeading(tableData.object) + tableData.headingOffset
                    local fightOffset = 0.65
                    local fightHeadOffset = 8.0

                    tableData.playerPositions = {
                        a = {
                            pos = objCoords + vector3(
                                math.cos(math.rad(objHeading)),
                                math.sin(math.rad(objHeading)),
                                0.0
                            ),
                            fightPos = objCoords + vector3(
                                fightOffset * math.cos(math.rad(objHeading - fightHeadOffset)),
                                fightOffset * math.sin(math.rad(objHeading - fightHeadOffset)),
                                0.0
                            ),
                            heading = (objHeading + 90.0) % 360.0,
                        },
                        b = {
                            pos = objCoords - vector3(
                                math.cos(math.rad(objHeading)),
                                math.sin(math.rad(objHeading)),
                                0.0
                            ),
                            fightPos = objCoords - vector3(
                                fightOffset * math.cos(math.rad(objHeading - fightHeadOffset)),
                                fightOffset * math.sin(math.rad(objHeading - fightHeadOffset)),
                                0.0
                            ),
                            heading = (objHeading + 90.0 + 180.0) % 360.0,
                        },
                    }
                end

                table.insert(closest, tableIdx)
            elseif tableData.object then
                tableData.object = nil
            end
        end

        ClosestTableIndices = closest
    end
end)

Citizen.CreateThread(function()
    AddTextEntry('LS_ARM_S', '~' .. CONTROLS.PLAY.CONTROL_LABEL .. '~ ' .. CONTROLS.PLAY.TEXT)

    while true do
        local lenClosestTableIndices = #ClosestTableIndices
        if lenClosestTableIndices > 0 and not ACTIVE_TABLE_DATA then
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for i = 1, lenClosestTableIndices do
                local tableIdx = ClosestTableIndices[i]
                local tableData = TABLES[tableIdx]

                HandlePlayerMarker(coords, tableIdx, 'a')
                HandlePlayerMarker(coords, tableIdx, 'b')
            end
        else
            Wait(1000)
        end
    end
end)

function HandlePlayerMarker(pedCoords, tableId, positionId)
    if tableId and TABLES[tableId] and TABLES[tableId].playerPositions and not (TABLES[tableId].players and TABLES[tableId].players[positionId]) then
        local checkpointPos = TABLES[tableId].playerPositions[positionId].pos

        DrawMarker(
            1, 
            checkpointPos.x, checkpointPos.y, checkpointPos.z - 1.0, 
            0.0, 0.0, 0.0, 
            0.0, 0.0, 0.0, 
            1.0, 1.0, 1.0, 
            CHECKPOINT_COLOR.r, CHECKPOINT_COLOR.g, CHECKPOINT_COLOR.b, CHECKPOINT_COLOR.a, 
            false, false, false, false, nil, nil, false
        )

        if #(checkpointPos - pedCoords) < 0.75 then
            DisplayHelpTextThisFrame('LS_ARM_S', false)

            if IsControlJustPressed(0, CONTROLS.PLAY.CONTROL) or IsDisabledControlJustPressed(0, CONTROLS.PLAY.CONTROL) then
                TriggerServerEvent('lsrp_arm_wrestling:requestPosition', tableId, positionId)
            end
        end
    end
end

RegisterNetEvent('lsrp_arm_wrestling:grantPosition')
AddEventHandler('lsrp_arm_wrestling:grantPosition', function(tableId, positionId)
    local ped = PlayerPedId()
    local pointData = TABLES[tableId].playerPositions[positionId]

    MovePedToCoordWithBackpressure(
        ped, pointData.fightPos, pointData.heading, 
        2.0, 2
    )
    StartGameThread(tableId, positionId)
end)

RegisterNetEvent('lsrp_arm_wrestling:denyPosition')
AddEventHandler('lsrp_arm_wrestling:denyPosition', function()
    TriggerEvent('lsrp_utils:showNotification', 'Na této straně stolu již stojí někdo jiný.')
end)

RegisterNetEvent('lsrp_arm_wrestling:start')
AddEventHandler('lsrp_arm_wrestling:start', function(tableId, positionId)
    Wait(2000)
    if ACTIVE_TABLE_DATA and ACTIVE_TABLE_DATA.table == tableId and ACTIVE_TABLE_DATA.position == positionId then
        ACTIVE_TABLE_DATA.startedAt = GetGameTimer() + 3 * 1000
        ACTIVE_TABLE_DATA.secNotified = nil
        ACTIVE_TABLE_DATA.phase = 'fight'
        ACTIVE_TABLE_DATA.state = 0.5
    end
end)

function StartGameThread(tableId, positionId)
    LoadAnimDict(ARM_WREST_DICT)

    local ped = PlayerPedId()
    local startHp = GetEntityHealth(ped)


    if not ACTIVE_TABLE_DATA then
        ACTIVE_TABLE_DATA = {
            table = tableId,
            position = positionId,
            phase = 'idle'
        }

        local instructScaleform = setupInstructionalScaleform("instructional_buttons")

        while ACTIVE_TABLE_DATA do

            local gameTime = GetGameTimer()
            local isGameStarted = false

            if startHp ~= GetEntityHealth(ped) then
                FullSelfQuit(ped)
                break
            end

            if ACTIVE_TABLE_DATA.startedAt then
                local secLeft = tonumber(math.floor((gameTime - ACTIVE_TABLE_DATA.startedAt)/1000))

                if secLeft < 0 then
                    local timeToStart = math.abs(secLeft)

                    DisplayCountdown(timeToStart)
                elseif secLeft == 0 then
                    DisplayCountdown(0)
                    isGameStarted = true
                else
                    CleanupScaleform()
                    isGameStarted = true
                end
            end

            if ACTIVE_TABLE_DATA.phase == 'idle' then
                EnsureAnim(ped, 'nuetral_idle_' .. ACTIVE_TABLE_DATA.position, 1, not not ACTIVE_TABLE_DATA.startedAt, not ACTIVE_TABLE_DATA.startedAt)
            elseif ACTIVE_TABLE_DATA.phase == 'fight' then
                AdvancedAnim(ped, 'sweep_' .. ACTIVE_TABLE_DATA.position, ACTIVE_TABLE_DATA.state)
                DrawScaleformMovieFullscreen(instructScaleform, 255, 255, 255, 255, 0)

                if isGameStarted then
                    HandleFightKeypress()
                end
            end

            if IsControlJustPressed(0, CONTROLS.QUIT.CONTROL) or IsDisabledControlJustPressed(0, CONTROLS.QUIT.CONTROL) then
                FullSelfQuit(ped)
            end
            Wait(0)
        end

        SetScaleformMovieAsNoLongerNeeded(instructScaleform)
    else
        print("ERROR: Game thread is already active!")
    end
end

function FullSelfQuit(ped)
    TriggerServerEvent('lsrp_arm_wrestling:quit')
    ClearPedTasks(ped)
    Wait(0)
    ClearPedTasks(ped)
    Wait(0)
    ClearPedTasks(ped)
    ACTIVE_TABLE_DATA = nil
end

local StoredKeypresses = 0
local lastFlushedValue = 0
local expectingA = true
local expectingD = true
local lastFlush = nil

function HandleFightKeypress()
    local nowTime = GetGameTimer()
    
    if not lastFlush or (nowTime - lastFlush) > 2000 then
        lastFlush = nowTime
    elseif (nowTime - lastFlush) > 500 then
        FlushKeypresses(nowTime)
    end

    if IsControlJustPressed(0, CONTROLS.MASH_A.CONTROL) or IsDisabledControlJustPressed(0, CONTROLS.MASH_A.CONTROL) then
        if expectingA then
            expectingA = false
            expectingD = true
            StoredKeypresses = StoredKeypresses + 1
        end
    end

    if IsControlJustPressed(0, CONTROLS.MASH_B.CONTROL) or IsDisabledControlJustPressed(0, CONTROLS.MASH_B.CONTROL) then
        if expectingD then
            expectingD = false
            expectingA = true
            StoredKeypresses = StoredKeypresses + 1
        end
    end
end

function FlushKeypresses(nowTime)
    lastFlushedValue = StoredKeypresses
    TriggerServerEvent('lsrp_arm_wrestling:flush', StoredKeypresses)
    StoredKeypresses = 0
    lastFlush = nowTime
end


function AdvancedAnim(ped, anim, time)
    local coords = GetEntityCoords(ped)
    local rot = GetEntityRotation(ped, 2)

    TaskPlayAnimAdvanced(
        ped, ARM_WREST_DICT, anim, 
        coords.x, coords.y, coords.z, 
        rot.x, rot.y, rot.z, 
        8.0, 8.0, 
        1000, 0, time, false, false
    )
end

function EnsureAnim(ped, anim, flag, fastIn, fastOut)
    if not IsEntityPlayingAnim(ped, ARM_WREST_DICT, anim, 3) then
        TaskPlayAnim(ped, ARM_WREST_DICT, anim, fastIn and 8.0 or 1.0, fastOut and 8.0 or 1.0, -1, flag, 1.0, false, false, false)
    end
end

function MovePedToCoordWithBackpressure(ped, pos, heading, slideDist, backpressureSeconds)
    TaskGoStraightToCoord(ped, pos.x, pos.y, pos.z+0.5, 1.0, -1, heading, slideDist)

    repeat
        Wait(0)
        backpressureSeconds = backpressureSeconds - GetFrameTime()
        local newCoords = GetEntityCoords(ped)
        local newHeading = GetEntityHeading(ped)

        local coordsDiff = #(newCoords.xy - pos.xy)
        local headingDiff = math.abs(newHeading - heading)
    until (coordsDiff < 0.1 and headingDiff < 5) or backpressureSeconds < 0.0


    Wait(100)
    
    SetEntityHeading(ped, heading)

    Wait(100)
    
    SetEntityHeading(ped, heading)
    
    Wait(100)
end

function LoadAnimDict(animDict)
	while (not HasAnimDictLoaded(animDict)) do
		RequestAnimDict(animDict)
		Citizen.Wait(0)
    end

    Wait(0)
end

RegisterNetEvent('lsrp_arm_wrestling:setPositionTaken')
AddEventHandler('lsrp_arm_wrestling:setPositionTaken', function(tableId, posId)
    if not TABLES[tableId].players then
        TABLES[tableId].players = {}
    end

    TABLES[tableId].players[posId] = true
end)

RegisterNetEvent('lsrp_arm_wrestling:setPositionReleased')
AddEventHandler('lsrp_arm_wrestling:setPositionReleased', function(tableId, posId)
    if TABLES[tableId].players then
        TABLES[tableId].players[posId] = nil

        if ACTIVE_TABLE_DATA and ACTIVE_TABLE_DATA.table == tableId then
            ACTIVE_TABLE_DATA.startedAt = nil
        end
    end
end)

function lerp(a,b,t) return a * (1-t) + b * t end

stateSetId = 0
RegisterNetEvent('lsrp_arm_wrestling:setState')
AddEventHandler('lsrp_arm_wrestling:setState', function(state)
    if ACTIVE_TABLE_DATA then
        local wantedEndTime = GetGameTimer() + 800
        local oldState = ACTIVE_TABLE_DATA.state or 0.5

        -- prevents old state from overriding new state
        stateSetId = stateSetId + 1
        local myStateId = stateSetId

        while ACTIVE_TABLE_DATA and GetGameTimer() < wantedEndTime and myStateId == stateSetId do
            local elapsedTime = 1.0 - math.min(1.0, math.max(0.0, (wantedEndTime - GetGameTimer())/800))

            ACTIVE_TABLE_DATA.state = lerp(oldState, state, elapsedTime)

            if elapsedTime >= 1.0 then
                break
            end

            Wait(0)
        end
    end
end)

RegisterNetEvent('lsrp_arm_wrestling:end')
AddEventHandler('lsrp_arm_wrestling:end', function(endType)
    LoadAnimDict(ARM_WREST_DICT)
    local myPosition = ACTIVE_TABLE_DATA.position
    ACTIVE_TABLE_DATA = nil

    local ped = PlayerPedId()

    if endType == 'timeout' then
        if myPosition == 'a' then
            TaskPlayAnim(ped, ARM_WREST_DICT, 'win_b_ped_a', 1.0, 1.0, 3000, 0, 0, 0, 0, 0 )
        else
            TaskPlayAnim(ped, ARM_WREST_DICT, 'win_a_ped_b', 1.0, 1.0, 3000, 0, 0, 0, 0, 0 )
        end
    elseif endType == 'win_a' then
        if myPosition == 'a' then
            TaskPlayAnim(ped, ARM_WREST_DICT, 'win_a_ped_a', 1.0, 1.0, 3000, 0, 0, 0, 0, 0 )
        else
            TaskPlayAnim(ped, ARM_WREST_DICT, 'win_a_ped_b', 1.0, 1.0, 3000, 0, 0, 0, 0, 0 )
        end
    elseif endType == 'win_b' then
        if myPosition == 'a' then
            TaskPlayAnim(ped, ARM_WREST_DICT, 'win_b_ped_a', 1.0, 1.0, 3000, 0, 0, 0, 0, 0 )
        else
            TaskPlayAnim(ped, ARM_WREST_DICT, 'win_b_ped_b', 1.0, 1.0, 3000, 0, 0, 0, 0, 0 )
        end
    elseif endType == 'stop' then
        ClearPedTasks(ped)
    end

    RemoveAnimDict(ARM_WREST_DICT)
end)
