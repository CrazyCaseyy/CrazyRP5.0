local function SimulateShotToGoal(o, startPos, startVel, targetSide, maxFrames)
    local pos = vector2(startPos.x, startPos.y)
    local vel = vector2(startVel.x, startVel.y)

    local dt = 0.033
    local r = o.ballData.radius
    local min = o.playableMinBall
    local max = o.playableMaxBall

    local goalMinX, goalMaxX = -0.13, 0.13
    local goalY = (targetSide == 1) and min.y or max.y

    for i = 1, (maxFrames or 90) do
        pos = pos + vel * dt

        -- X walls bounce
        if pos.x - r < min.x then
            pos = vector2(min.x + r, pos.y)
            vel = vector2(math.abs(vel.x), vel.y)
        elseif pos.x + r > max.x then
            pos = vector2(max.x - r, pos.y)
            vel = vector2(-math.abs(vel.x), vel.y)
        end

        -- Y walls bounce (but before bouncing, check if it crossed the goal line)
        if targetSide == 1 then
            if pos.y - r <= goalY then
                local isGoal = (pos.x >= goalMinX and pos.x <= goalMaxX)
                return isGoal, pos, i
            end
        else
            if pos.y + r >= goalY then
                local isGoal = (pos.x >= goalMinX and pos.x <= goalMaxX)
                return isGoal, pos, i
            end
        end

        if pos.y - r < min.y then
            pos = vector2(pos.x, min.y + r)
            vel = vector2(vel.x, math.abs(vel.y))
        elseif pos.y + r > max.y then
            pos = vector2(pos.x, max.y - r)
            vel = vector2(vel.x, -math.abs(vel.y))
        end
    end

    return false, pos, (maxFrames or 90)
end

-- Convert playable XY to normalized mouse-space XY (what pData.position expects)
-- NOTE: your existing toNormalized swaps axes; keep it consistent with handleMovement mapping.
local function PlayableToNorm(o, playable)
    local nx = (playable.y - o.playableMin.y) / (o.playableMax.y - o.playableMin.y) -- maps to "actualPosition.x"
    local ny = (playable.x - o.playableMin.x) / (o.playableMax.x - o.playableMin.x) -- maps to "actualPosition.y"
    return vector2(nx, ny)
end

local function ClampPlayableToSide(o, side, p)
    local centerY = (o.playableMin.y + o.playableMax.y) * 0.5
    local minY = (side == 1) and o.playableMin.y or centerY
    local maxY = (side == 1) and centerY or o.playableMax.y

    return vector2(Clamp(p.x, o.playableMin.x, o.playableMax.x), Clamp(p.y, minY, maxY))
end

-- Very cheap intercept: simulate forward until puck reaches a given y (hitLineY) or maxFrames.
-- Uses your wall bounces (same as predictBallPosition) so it matches gameplay.
local function PredictAtY(o, startPos, startVel, hitLineY, maxFrames)
    local pos = vector2(startPos.x, startPos.y)
    local vel = vector2(startVel.x, startVel.y)

    local dt = 0.033
    local r = o.ballData.radius
    local min = o.playableMinBall
    local max = o.playableMaxBall

    for i = 1, (maxFrames or 90) do
        pos = pos + vel * dt

        -- X walls
        if pos.x - r < min.x then
            pos = vector2(min.x + r, pos.y)
            vel = vector2(math.abs(vel.x), vel.y)
        elseif pos.x + r > max.x then
            pos = vector2(max.x - r, pos.y)
            vel = vector2(-math.abs(vel.x), vel.y)
        end

        -- Y walls (normal bounce, we don't goal-check here)
        if pos.y - r < min.y then
            pos = vector2(pos.x, min.y + r)
            vel = vector2(vel.x, math.abs(vel.y))
        elseif pos.y + r > max.y then
            pos = vector2(pos.x, max.y - r)
            vel = vector2(vel.x, -math.abs(vel.y))
        end

        if (startPos.y < hitLineY and pos.y >= hitLineY) or (startPos.y > hitLineY and pos.y <= hitLineY) then
            return pos, i
        end
    end

    return pos, (maxFrames or 90)
end

-- save table data
function CreateAirHockeyTable(coords, heading)
    local o = {}
    o.tableCoords = coords
    o.tableHeading = heading

    o.subscribed = false
    o.nearBy = false
    o.playableObjects = {}
    o.replayObjects = {}

    o.lastBallHit = 0
    o.lastRemoteHitTime = 0
    o.lastMovementUpdate = 0
    o.lastReplayPack = 0

    o.replayFrames = {}
    o.camera = nil
    o.replayActive = false

    o.resetBall = function()
        o.ballData = {
            playablePosition = vector2(0.0, 0.0),
            hitOrigin = 0,
            enemyHitTime = 0,
            touched = false,
            radius = 0.05,
            x = 0.0,
            y = 0.0,
            velocity = vector2(0, 0),
            actualSide = 0,
            sideChangedTime = 0,
            allowSound = true,
            skin = 1,
            goalTriggered = false
        }
    end

    o.resetPositions = function()
        o.resetBall()
        o.lastBallHit = 0
        o.lastMovementUpdate = 0
        o.lastPositionSendTime = 0
        o.lastRemoteHitTime = 0
        o.lastReplayPack = 0
        o.replayFrames = {}
        o.replayActive = false
        o.replayToken = (o.replayToken or 0) + 1
        o.playerData = {{
            closeHitsAllowed = 3,
            currentAlpha = 255,
            radius = 0.075,
            ped = nil,
            phase = 0.0,
            scene = nil,
            actualPosition = vector2(0, 0),
            velocity = vector2(0, 0),
            position = vector2(0, 0),
            remotePosition = vector2(0, 0),
            moveSpeed = 0,
            x = 0.0,
            y = 0.0,
            replayX = 0,
            playablePosition = vector2(0, 0),
            replayY = 0,
            skin = 1,
            hitsAgo = 0
        }, {
            closeHitsAllowed = 3,
            currentAlpha = 255,
            radius = 0.075,
            ped = nil,
            phase = 0.0,
            scene = nil,
            actualPosition = vector2(0, 0),
            velocity = vector2(0, 0),
            mass = 1.0,
            position = vector2(0, 0),
            remotePosition = vector2(0, 0),
            x = 0.0,
            y = 0.0,
            playablePosition = vector2(0, 0),
            moveSpeed = 0,
            replayX = 0,
            replayY = 0,
            skin = 1,
            hitsAgo = 0
        }}
        o.needSave = nil
    end

    -- create paddles and ball object
    o.createPlayableObjects = function()
        -- delete old if exists
        o.deletePlayableObjects()

        LoadHockeyElements()
        o.playableObjects[1] = CreateObject(Models.RcorePuck, o.tableCoords, false, false, false)
        o.playableObjects[2] = CreateObject(Models.RcorePaddle, o.tableCoords, false, false, false)
        o.playableObjects[3] = CreateObject(Models.RcorePaddle, o.tableCoords, false, false, false)

        o.disableCollisions()
    end

    -- create paddles and ball object for replay
    o.createReplayObjects = function()
        -- delete old if exists
        o.deleteReplayObjects()

        LoadHockeyElements()
        o.replayObjects[1] = CreateObject(Models.RcorePuck, o.tableCoords, false, false, false)
        o.replayObjects[2] = CreateObject(Models.RcorePaddle, o.tableCoords, false, false, false)
        o.replayObjects[3] = CreateObject(Models.RcorePaddle, o.tableCoords, false, false, false)
        o.disableCollisions()
    end

    o.startReplayer = function()
        if o.replayActive then
            return
        end
        o.replayToken = (o.replayToken or 0) + 1
        local replayToken = o.replayToken
        o.replayActive = true
        o.replayFrames = {}
        CreateThread(function()
            local playerIds = nil
            local function cleanupReplay()
                o.deleteReplayObjects()
                o.replayActive = false
                if playerIds then
                    ScenePed_EndForPlayer(playerIds[1])
                    ScenePed_EndForPlayer(playerIds[2])
                end
            end

            if replayToken ~= o.replayToken then
                cleanupReplay()
                return
            end
            o.createReplayObjects()

            local t = GetGameTimer() + 3000
            RequestAnimDict("rcore@airhockey")
            while GetGameTimer() < t and not HasAnimDictLoaded("rcore@airhockey") do
                Wait(33)
            end

            for i = 1, 2 do
                if replayToken ~= o.replayToken or not o.players or not o.players[i] or not o.players[i].netId then
                    cleanupReplay()
                    return
                end
            end

            for i = 1, 2 do
                local x = o.players[i]
                if x then
                    local state = GetCloneOfNetworkedPed(x.playerId, x.netId)
                    local pSide = x.side
                    o.playerData[pSide].cloneState = state
                    if state then
                        o.playerData[pSide].ped = state.clone
                        o.playerData[pSide].pedOriginal = state.ped
                        FreezeEntityPosition(state.clone, true)
                        ToggleUse(state, false)
                    else
                        o.playerData[pSide].ped = 0
                        o.playerData[pSide].pedOriginal = 0
                    end
                    if o.playerData[pSide].ped ~= 0 and DoesEntityExist(o.playerData[pSide].ped) then
                        TaskPlayAnim(o.playerData[pSide].ped, "rcore@airhockey", "gameplay_clip", 8.0, 1.0, 0.0001, 01,
                            0, 0, 0, 0)
                    end
                end
            end

            for i = 1, 2 do
                if replayToken ~= o.replayToken or not o.players or not o.players[i] or not o.players[i].netId then
                    cleanupReplay()
                    return
                end
            end

            -- wait for enough frames
            t = GetGameTimer() + 3000
            while GetGameTimer() < t and #o.replayFrames < 60 do
                if replayToken ~= o.replayToken then
                    cleanupReplay()
                    return
                end
                Wait(33)
            end

            local nextPlayTime = GetGameTimer()
            local frame = nil
            playerIds = {o.players[1].playerId, o.players[2].playerId}
            local textWorldPos = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, -0.0, -0.0, 1.5)

            while GetGameTimer() - o.lastReplayPack < 1500 do
                if replayToken ~= o.replayToken then
                    cleanupReplay()
                    return
                end
                if not o.replayObjects[1] or not o.replayObjects[2] or not o.replayObjects[3] then
                    cleanupReplay()
                    return
                end
                -- display replay frame
                local gt = GetGameTimer()

                if gt >= nextPlayTime and #o.replayFrames > 1 then
                    frame = o.replayFrames[1]
                    table.remove(o.replayFrames, 1)
                    nextPlayTime = gt + 33
                end

                if frame then
                    o.setReplayerPosition(1, frame.p1x, frame.p1y, frame.s)
                    o.setReplayerPosition(2, frame.p2x, frame.p2y, frame.s)
                    o.setReplayBallPosition(frame.ballx, frame.bally)

                    if frame.skins then
                        o.playerData[1].skin = frame.skins[1]
                        o.playerData[2].skin = frame.skins[2]
                        o.ballData.skin = frame.skins[3]
                        SetObjectTextureVariant(o.replayObjects[1], o.ballData.skin - 1)
                        SetObjectTextureVariant(o.replayObjects[2], o.playerData[1].skin - 1)
                        SetObjectTextureVariant(o.replayObjects[3], o.playerData[2].skin - 1)
                    end
                end

                if Config.DrawTableScore then
                    DrawText3Ds(textWorldPos.x, textWorldPos.y, textWorldPos.z, o.players[1].name .. "(" ..
                        o.players[1].score .. ") vs " .. o.players[2].name .. "(" .. o.players[2].score .. ")")
                end
                Wait(0)
            end
            cleanupReplay()
        end)
    end

    o.packFrame = function(isFinal, sendSkins)
        local pack = {
            p1x = o.playerData[1].playablePosition.x,
            p1y = o.playerData[1].playablePosition.y,
            p2x = o.playerData[2].playablePosition.x,
            p2y = o.playerData[2].playablePosition.y,
            ballx = o.ballData.playablePosition.x,
            bally = o.ballData.playablePosition.y,
            s = s_Session.recordPeds
        }

        if sendSkins then
            pack.skins = {o.playerData[1].skin, o.playerData[2].skin, o.ballData.skin}
        end

        table.insert(s_Session.replayPack, pack)
        if #s_Session.replayPack >= 30 or isFinal then
            TriggerServerEvent("AirHockey:ReplayPack", o.tableCoords, s_Session.replayPack, isFinal)
            s_Session.replayPack = {}
        end
    end

    o.replayPackReceived = function(pack)
        o.lastReplayPack = GetGameTimer()
        for k, v in pairs(pack) do
            table.insert(o.replayFrames, v)
        end
        local maxReplayFrames = 300
        if #o.replayFrames > maxReplayFrames then
            for _ = 1, #o.replayFrames - maxReplayFrames do
                table.remove(o.replayFrames, 1)
            end
        end
        o.startReplayer()
    end

    -- disable collisions between objects
    o.disableCollisions = function()
        for i = 1, 3 do
            if o.replayObjects[i] then
                SetEntityCompletelyDisableCollision(o.replayObjects[i], false, false)
            end
            if o.playableObjects[i] then
                SetEntityCompletelyDisableCollision(o.playableObjects[i], false, false)
            end
        end
    end

    -- get ped initial coords (standing)
    o.getPlayerPosition = function(pid, xoffset)
        if not xoffset then
            xoffset = 0.0
        end
        if pid == 1 then
            return GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, xoffset, -1.4, 1.0)
        else
            return GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, xoffset, 1.4, 1.0)
        end
    end

    o.setReplayerPosition = function(playerId, playableX, playableY, used)
        SetEntityCoordsNoOffset(o.replayObjects[playerId + 1], GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading,
            playableX, playableY, o.playerZ))

        playableX = Clamp(playableX, -0.454, 0.454)
        playableY = Clamp(playableY, -0.919, 0.918)

        local percent = 0
        if playerId == 1 then
            percent = (playableY - -0.919) / 0.919 * 1.0
        else
            percent = 1.0 * (playableY - 0.918) / -0.918
        end

        if o.playerData[playerId].cloneState then
            ToggleUse(o.playerData[playerId].cloneState, used)
        end
        local ped = o.playerData[playerId].ped
        if ped ~= 0 and DoesEntityExist(ped) then
            SetEntityAnimCurrentTime(ped, "rcore@airhockey", "gameplay_clip", percent)
            SetEntityCoordsNoOffset(ped, o.getPlayerPosition(playerId, playableX), true, true, true)
            SetEntityHeading(ped, o.tableHeading + (playerId == 1 and 0.0 or 180.0))
        end
    end

    -- set puck coords
    o.setReplayBallPosition = function(x, y)
        SetEntityCoordsNoOffset(o.replayObjects[1],
            GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, x, y, o.ballZ))
    end

    -- delete paddles & puck
    o.deletePlayableObjects = function()
        for i = 1, 6 do
            if o.playableObjects[i] then
                DeleteEntity(o.playableObjects[i])
                o.playableObjects[i] = nil
            end
        end
    end

    -- delete paddles & puck for replay
    o.deleteReplayObjects = function()
        for i = 1, 3 do
            if o.replayObjects[i] then
                DeleteEntity(o.replayObjects[i])
                o.replayObjects[i] = nil
            end
        end
    end

    -- enable shaking camera (while loading)
    o.enableIdleCamera = function()
        o.disableCamera()
        local cameraOffset = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading - 45.0, 1.5, 1.5, 2.0)
        o.camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cameraOffset, 0.0, 0.0, 0.0, 60.0)

        SetCamActive(o.camera, true)
        RenderScriptCams(true, true, 3000)
        PointCamAtCoord(o.camera, o.tableCoords)
        ShakeCam(o.camera, "HAND_SHAKE", 0.0)
    end

    o.enableWatcherView = function()
        if o.watcherView then
            return
        end
        o.watcherView = true
        local views = {{
            from = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, -0.50, 1.7),
            to = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, -0.50, 1.7),
            fromRot = vector3(-90.0 + 50.0, 0.0, o.tableHeading + 0.0),
            toRot = vector3(-90.0 + 70.0, 0.0, o.tableHeading + 0.0)
        }, {
            from = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, 0.50, 1.7),
            to = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, 0.50, 1.7),
            fromRot = vector3(-90.0 + 50.0, 0.0, o.tableHeading + 180.0),
            toRot = vector3(-90.0 + 70.0, 0.0, o.tableHeading + 180.0)
        }, {
            from = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, 0.00, 2.2),
            to = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, 0.00, 2.5),
            fromRot = vector3(-90.0, 0.0, o.tableHeading + 90.0),
            toRot = vector3(-90.0, 0.0, o.tableHeading + 90.0)
        }}
        local actualView = 3

        o.disableCamera()

        local cameraOffset = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, 0.00, 2.2)
        o.camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cameraOffset, -90.0, 0.0, o.tableHeading + 90.0, 60.0)
        SetCamActive(o.camera, true)
        RenderScriptCams(true, true, 0)

        CreateThread(function()
            local actualPos = views[actualView].from
            local actualRot = views[actualView].fromRot

            while true do
                if not o.watcherView or not o.camera then
                    break
                end
                if IsControlJustPressed(2, 22) then
                    actualView = actualView < 3 and actualView + 1 or 1
                    actualPos = views[actualView].from
                    actualRot = views[actualView].fromRot
                end
                HideHudAndRadarThisFrame()
                actualPos = Vector2Lerp(actualPos, views[actualView].to, 0.001)
                actualRot = Vector2Lerp(actualRot, views[actualView].toRot, 0.001)
                SetCamCoord(o.camera, actualPos.x, actualPos.y, actualPos.z)
                SetCamRot(o.camera, actualRot.x, actualRot.y, actualRot.z, 2)
                Wait(0)
            end
        end)

    end

    -- gets X Y player/ball coordinates (0.0 - 1.0) from cursor position
    o.getDeltaFromMouse = function()
        local _, minx, miny = World3dToScreen2d(o.topLeft.x, o.topLeft.y, o.topLeft.z)
        local _, maxx, maxy = World3dToScreen2d(o.bottomRight.x, o.bottomRight.y, o.bottomRight.z)

        -- if borders aren't visible
        if minx == -1.0 or miny == -1.0 or maxx == -1.0 or maxy == -1.0 then
            if o.camera then
                local actualFov = GetCamFov(o.camera)
                if actualFov < 120.0 then
                    SetCamFov(o.camera, actualFov + 0.1)
                end
            end
        end

        local mX, mY = GetNuiCursorPosition()
        local rX, rY = GetActiveScreenResolution()

        local mXP = mX * 1.0 / rX
        local mYP = mY * 1.0 / rY

        return Clamp((mXP - minx) / (maxx - minx) * 1.0, 0.0, 1.0), Clamp((mYP - miny) / (maxy - miny) * 1.0, 0.0, 1.0)
    end

    o.animateGoal = function(net)

    end

    o.onGoalTrigger = function(net)
        if o.ballData.goalTriggered then
            return
        end
        o.ballData.goalTriggered = true
        o.needSave = nil
        if net == s_Session.localSide or s_Session.isAI then
            OnGoal(net, true)
        end
    end

    o.opHitReceived = function(msg)
        if not s_Session or not s_Session.roundStarted then
            return
        end
        local syncedTime = GetSyncedGameTimer()
        local msgTime = msg.t or syncedTime
        o.ballData.pendingStates = o.ballData.pendingStates or {}
        table.insert(o.ballData.pendingStates, {
            playablePosition = vector2(msg.x, msg.y),
            velocity = vector2(msg.vx, msg.vy),
            t = msgTime,
            saved = msg.saved
        })

        local opId = s_Session.localSide == 1 and 2 or 1
        local newPos = vector2(msg.px, msg.py)
        local pDiff = #(o.playerData[opId].playablePosition - newPos)

        o.playerData[opId].hitsAgo = 0

        if pDiff > 0.05 then
            o.playerData[opId].playablePosition = vector2(msg.px, msg.py)
            o.playerData[opId].remotePosition = vector2(msg.px, msg.py)
        end
    end

    o.opCoordsReceived = function(msg)
        local opId = s_Session.localSide == 1 and 2 or 1
        o.playerData[opId].remotePosition = vector2(msg.x, msg.y)
    end

    o.toggleTicking = function(toggle)
        if s_Session then
            s_Session.sideTicking = toggle
        end
        if toggle then
            if not s_tickingBar then
                s_Session.tickSound = GetSoundId()
                PlaySoundFrontend(s_Session.tickSound, "10s", "MP_MISSION_COUNTDOWN_SOUNDSET")
                s_tickingBar = TimerBar.Create(TimerBar.Progress, Translation.Get("TIMERBAR_PENALTY"), 0.0)
                s_tickingBar.setBackgroundColor({255, 255, 255, 50})
                s_tickingBar.setForegroundColor({255, 255, 255, 150})
                s_tickingBar.setHighlightColor({255, 20, 20, 255})
            end
        else
            if s_Session.tickSound then
                StopSound(s_Session.tickSound)
                s_Session.tickSound = nil
            end
            if s_tickingBar then
                TimerBar.DestroyAll()
                s_tickingBar = nil
            end
        end
    end

    o.handleAIMovement = function(delta)
        local aiSide = (s_Session.localSide == 1) and 2 or 1
        local pData = o.playerData[aiSide]
        if not pData then
            return
        end

        local now = GetGameTimer()

        -- ===== Difficulty (0.0 easy .. 1.0 hard) =====
        o.aiDifficulty = s_Session.settings.difficulty or 0.5

        -- HARD speed cap in PLAYABLE units per second (this is the main "easiness" knob)
        -- Try: 0.40 (very easy), 0.55 (easy), 0.70 (medium), 0.90 (hard)
        o.maxSpeedPlayable = o.maxSpeedPlayable or 2.7
        -- =============================================

        -- ===== Tunables =====
        local REACTION_MS = 55 -- slower thinking helps too
        local LOOKAHEAD_FRAMES = 110
        local GUARD_OFFSET = 0.13
        local HITLINE_OFFSET = 0.22
        local BEHIND_PUCK = 0.075
        local AIM_ERROR = 0.02

        local KP = 1.8 -- lower -> less snappy
        local KD = 0.60
        local MAX_STEP = 0.12 -- still keep, but speed cap below dominates

        local STRIKE_COOLDOWN_MS = 650
        local CLEAR_SPEED = 0.35
        local STRIKE_DASH = 0.32
        local STRIKE_TIME_MS = 150
        -- ====================

        -- State vars
        o.aiState = o.aiState or "DEFEND"
        o.lastAiState = o.lastAiState or ""
        o.aiNextThinkTime = o.aiNextThinkTime or 0
        o.aiLastStrikeTime = o.aiLastStrikeTime or 0

        local ballPos = o.ballData.playablePosition
        local ballVel = o.ballData.velocity
        local ballSpeed = math.sqrt(ballVel.x * ballVel.x + ballVel.y * ballVel.y)

        local toOppSign = (aiSide == 1) and 1 or -1
        local towardAI = (aiSide == 1) and (ballVel.y < -0.02) or (aiSide == 2 and ballVel.y > 0.02)

        local baseY = (aiSide == 1) and o.playableMin.y or o.playableMax.y
        local guardY = baseY + ((aiSide == 1) and GUARD_OFFSET or -GUARD_OFFSET)
        local hitLineY = baseY + ((aiSide == 1) and HITLINE_OFFSET or -HITLINE_OFFSET)

        local centerY = (o.playableMin.y + o.playableMax.y) * 0.5
        local onOurHalf = (aiSide == 1) and (ballPos.y <= centerY) or (aiSide == 2 and (ballPos.y >= centerY))
        local shouldClear = onOurHalf and (ballSpeed < CLEAR_SPEED or not towardAI)

        -- Think step
        if now >= o.aiNextThinkTime then
            -- add reaction delay scaling (easy = slower)
            local reactionScaled = REACTION_MS + math.floor((1.0 - o.aiDifficulty) * 120)
            o.aiNextThinkTime = now + reactionScaled

            if not towardAI and not shouldClear then
                o.aiState = "DEFEND"
            else
                local interceptPos
                if shouldClear then
                    interceptPos = ballPos
                else
                    interceptPos = PredictAtY(o, ballPos, ballVel, hitLineY, LOOKAHEAD_FRAMES)
                    local jitter = math.sin(now * 0.01) * (AIM_ERROR + (1.0 - o.aiDifficulty) * 0.05)
                    interceptPos = vector2(interceptPos.x + jitter, interceptPos.y)
                end

                o.aiIntercept = ClampPlayableToSide(o, aiSide, interceptPos)
                o.aiState = "SETUP"
            end
        end

        -- Choose targetPlayable
        local targetPlayable

        if o.lastAiState ~= o.aiState then
            o.lastAiState = o.aiState
            if o.aiState == "SETUP" then
                -- random max speed each setup (easier = slower)
                local min, max = 2.0, 2.5
                if o.aiDifficulty >= 0.8 then
                    min = 3.0
                    max = 3.5
                elseif o.aiDifficulty >= 0.6 then
                    min = 2.2 
                    max = 3.5
                else
                    min = 2.0
                    max = 2.5
                end
                o.maxSpeedPlayable = math.random() * (max - min) + min
            end
        end

        if o.aiState == "DEFEND" then
            local guardX = Clamp(ballPos.x, -0.25, 0.25)
            targetPlayable = ClampPlayableToSide(o, aiSide, vector2(guardX, guardY))

        elseif o.aiState == "SETUP" then
            local intercept = o.aiIntercept or vector2(0.0, hitLineY)
            local behindY = intercept.y - (toOppSign * BEHIND_PUCK)
            targetPlayable = ClampPlayableToSide(o, aiSide, vector2(intercept.x, behindY))

            -- Strike gating (make it rarer on easy)
            local paddleToPuck = #(pData.playablePosition - ballPos)
            local ATTACK_DIST = (o.ballData.radius or 0.05) + (pData.radius or 0.075) + 0.045

            local behindPuck = ((pData.playablePosition.y - ballPos.y) * toOppSign) < -0.01
            local alignedX = math.abs(pData.playablePosition.x - ballPos.x) <= 0.14
            local nearHitLine = math.abs(ballPos.y - hitLineY) <= 0.25

            local hesitate = (math.abs(math.sin(now * 0.0011)) * 0.999) < (0.55 - o.aiDifficulty * 0.45)

            if (towardAI or shouldClear) and behindPuck and alignedX and (nearHitLine or shouldClear) and paddleToPuck <=
                ATTACK_DIST and (now - o.aiLastStrikeTime) >= STRIKE_COOLDOWN_MS and not hesitate then
                o.aiState = "STRIKE"
                o.aiStrikeEndTime = now + STRIKE_TIME_MS
                o.aiLastStrikeTime = now
            end

        else -- STRIKE
            local intercept = o.aiIntercept or ballPos
            local dashY = intercept.y + (toOppSign * STRIKE_DASH)
            targetPlayable = ClampPlayableToSide(o, aiSide, vector2(intercept.x, dashY))

            if o.aiStrikeEndTime and now >= o.aiStrikeEndTime then
                o.aiState = "DEFEND"
            end
        end

        -- Convert to normalized + clamp
        local targetNorm = PlayableToNorm(o, targetPlayable)

        local minx = (aiSide == 1) and 0.0 or (o.useFivem and 0.63 or 0.55)
        local maxx = (aiSide == 1) and (o.useFivem and 0.37 or 0.45) or 1.0
        targetNorm = vector2(Clamp(targetNorm.x, minx, maxx), Clamp(targetNorm.y, 0.0, 1.0))

        -- =========================
        -- Movement
        -- =========================

        local dt = delta
        dt = math.min(dt, 0.05) 

        -- current playable position
        local curP = pData.playablePosition
        local tgtP = targetPlayable

        local dx = tgtP.x - curP.x
        local dy = tgtP.y - curP.y
        local dist = math.sqrt(dx * dx + dy * dy)

        local maxStep = o.maxSpeedPlayable * dt

        local newP
        if dist <= maxStep or dist < 1e-6 then
            newP = tgtP
        else
            local inv = 1.0 / dist
            newP = vector2(curP.x + dx * inv * maxStep, curP.y + dy * inv * maxStep)
        end

        newP = ClampPlayableToSide(o, aiSide, newP)

        -- convert back to normalized
        local norm = PlayableToNorm(o, newP)

        pData.position = vector2(Clamp(norm.x, minx, maxx), Clamp(norm.y, 0.0, 1.0))

        pData.aiSpeedMultiplier = 1.0
    end

    o.IsPuckGoingTowardsNet = function(side)
        local bd = o.ballData
        if not bd or not bd.playablePosition or not bd.velocity then
            return false
        end
        if side ~= 1 and side ~= 2 then
            return false
        end

        local px, py = bd.playablePosition.x, bd.playablePosition.y
        local vx, vy = bd.velocity.x, bd.velocity.y
        if math.abs(vy) < 0.0001 then
            return false
        end

        local goalY = (side == 1) and o.playableMinBall.y or o.playableMaxBall.y
        local toward = (side == 1) and (vy < 0.0) or (vy > 0.0)
        if not toward then
            return false
        end

        -- already past the line (your main goal check handles this elsewhere)
        if (side == 1 and py <= goalY) or (side == 2 and py >= goalY) then
            return false
        end

        local t = (goalY - py) / vy
        if t <= 0.0 then
            return false
        end

        local xAtGoal = px + vx * t
        return (xAtGoal >= -0.13 and xAtGoal <= 0.13)
    end

    o.predictBallPosition = function(fromCoords, fromVelocity, afterFrameCount)
        local currentCoord = vector2(fromCoords.x, fromCoords.y)
        local currentVel = vector2(fromVelocity.x, fromVelocity.y)

        local dt = 0.033
        local r = o.ballData.radius
        local min = o.playableMinBall
        local max = o.playableMaxBall

        for _ = 1, afterFrameCount do
            currentCoord = currentCoord + currentVel * dt

            -- X walls
            if currentCoord.x - r < min.x then
                currentCoord = vector2(min.x + r, currentCoord.y)
                currentVel = vector2(math.abs(currentVel.x), currentVel.y)
            elseif currentCoord.x + r > max.x then
                currentCoord = vector2(max.x - r, currentCoord.y)
                currentVel = vector2(-math.abs(currentVel.x), currentVel.y)
            end

            -- Y walls
            if currentCoord.y - r < min.y then
                currentCoord = vector2(currentCoord.x, min.y + r)
                currentVel = vector2(currentVel.x, math.abs(currentVel.y))
            elseif currentCoord.y + r > max.y then
                currentCoord = vector2(currentCoord.x, max.y - r)
                currentVel = vector2(currentVel.x, -math.abs(currentVel.y))
            end
        end
        return currentCoord
    end

    o.predictAttack = function(side, afterFrames)
        local puck = o.predictBallPosition(o.ballData.playablePosition, o.ballData.velocity, afterFrames)

        local centerY = (o.playableMin.y + o.playableMax.y) * 0.5
        local targetSide = (side == 1) and 2 or 1

        -- how hard AI can "shoot"
        local shotSpeed = 1.65

        -- paddle contact distance from puck center (tune this!)
        -- if you know paddle radius, use: o.ballData.radius + paddleRadius + smallMargin
        local contactDist = o.ballData.radius * 3.0

        -- helper: keep paddle on its half
        local function clampToSide(pos)
            local x = Clamp(pos.x, -0.4, 0.4)
            local y = pos.y
            if side == 1 then
                y = Clamp(y, o.playableMin.y + 0.05, centerY - 0.05)
            else
                y = Clamp(y, centerY + 0.05, o.playableMax.y - 0.05)
            end
            return vector2(x, y)
        end

        local bestScore = -1e9
        local bestAttackPos = nil
        local bestVel = nil

        -- We want puck to go toward opponent: for side 1 opponent is +Y, for side 2 opponent is -Y
        local desiredYSign = (targetSide == 2) and 1 or -1

        -- sample ring around puck (more samples = smarter but heavier)
        local samples = 16
        for i = 0, samples - 1 do
            local a = (math.pi * 2.0) * (i / samples)

            -- candidate paddle position around puck
            local offset = vector2(math.cos(a), math.sin(a)) * contactDist
            local attackPos = clampToSide(puck + offset)

            -- hit direction: from paddle -> puck (puck moves away from paddle)
            local dir = Vector2Normalized(puck - attackPos)

            -- prefer “forward” hits
            local forwardness = dir.y * desiredYSign

            -- if it’s not even pushing forward, heavily penalize
            if forwardness > -0.2 then
                local shotVel = vector2(dir.x * shotSpeed, dir.y * shotSpeed)

                -- optionally blend with current puck velocity so it feels more natural:
                -- local shotVel = (vector2(dir.x, dir.y) * shotSpeed) + (o.ballData.velocity * 0.15)

                local isGoal, endPos, frames = SimulateShotToGoal(o, puck, shotVel, targetSide, 120)

                -- scoring: goals win, else “closest to goal mouth” wins
                local goalCenterX = 0.0
                local xDist = math.abs(endPos.x - goalCenterX)

                local score = 0.0
                score = score + forwardness * 3.0
                score = score - xDist * 4.0
                score = score - (frames * 0.02) -- faster shots slightly better

                if isGoal then
                    score = score + 1000.0 -- always pick a scoring line if found
                end

                if score > bestScore then
                    bestScore = score
                    bestAttackPos = attackPos
                    bestVel = vector(dir.x, dir.y) * vector(shotSpeed, shotSpeed)
                end
            end
        end

        -- fallback if something went wrong
        if not bestAttackPos then
            local yOffset = contactDist * (side == 1 and -1 or 1)
            bestAttackPos = clampToSide(vector2(puck.x, puck.y + yOffset))
            local dir = Vector2Normalized(puck - bestAttackPos)
            bestVel = vector(dir.x, dir.y) * vector(shotSpeed, shotSpeed)
        end

        -- debug visuals 
        local worldBall = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, puck.x, puck.y, o.ballZ)
        local worldPaddle = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, bestAttackPos.x, bestAttackPos.y,
            o.playerZ)

        if not o.playableObjects[4] or not DoesEntityExist(o.playableObjects[4]) then
            o.playableObjects[4] = CreateObject(Models.RcorePuck, worldBall, false, false, false)
            SetEntityAlpha(o.playableObjects[4], 150)
        end
        if not o.playableObjects[5] or not DoesEntityExist(o.playableObjects[5]) then
            o.playableObjects[5] = CreateObject(Models.RcorePaddle, worldPaddle, false, false, false)
            SetEntityAlpha(o.playableObjects[5], 150)
        end
        SetEntityCoordsNoOffset(o.playableObjects[4], worldBall)
        SetEntityCoordsNoOffset(o.playableObjects[5], worldPaddle)

        return bestAttackPos, bestVel
    end

    o.handleMovement = function()
        local gT = GetGameTimer()
        local deltaSeconds = (gT - o.lastMovementUpdate) / 1000
        if o.lastMovementUpdate == 0 then
            deltaSeconds = 0
        end

        local delta = deltaSeconds * 10.0
        local everyoneClose = false

        if s_Session.playerMovement then
            if s_Session.isAI then
                o.handleAIMovement(delta)
            end
            for i = 1, 2 do
                local pData = o.playerData[i]
                if i == s_Session.localSide or s_Session.isAI then
                    -- player velocity
                    local distanceBetweenPlayers =
                        #(o.playerData[1].playablePosition - o.playerData[2].playablePosition)
                    local distanceBetweenBall = #(pData.playablePosition - o.ballData.playablePosition)
                    local distanceInTotal = distanceBetweenPlayers + distanceBetweenBall
                    everyoneClose = distanceInTotal <= 0.4

                    if not everyoneClose then
                        if pData.currentAlpha ~= 255 then
                            ResetEntityAlpha(o.playableObjects[i + 1])
                            pData.currentAlpha = 255
                        end
                        pData.closeHitsAllowed = 3
                    end

                    if math.abs(pData.velocity.x + pData.velocity.y) > 0.01 then
                        pData.velocity = pData.velocity * 0.99
                    end

                    local oldPos = pData.actualPosition
                    local aiSpeedMultiplier = 1
                    if s_Session.isAI and i ~= s_Session.localSide then
                        aiSpeedMultiplier = pData.aiSpeedMultiplier or 1
                    end
                    pData.actualPosition = Vector2Lerp(pData.actualPosition, pData.position,
                        pData.moveSpeed * delta * aiSpeedMultiplier)
                    local playerTravel = #(oldPos - pData.actualPosition)

                    local worldX = Lerp(o.playableMin.x, o.playableMax.x, pData.actualPosition.y)
                    local worldY = Lerp(o.playableMin.y, o.playableMax.y, pData.actualPosition.x)

                    pData.playablePosition = vector2(worldX, worldY)

                    local displayPos = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, worldX, worldY,
                        o.playerZ)

                    s_Session.playerTravelDistance = s_Session.playerTravelDistance + playerTravel

                    SetEntityCoordsNoOffset(o.playableObjects[i + 1], displayPos)

                    if not s_Session.isAI then
                        if GetGameTimer() - o.lastPositionSendTime > Config.PositionSendRate then
                            opponentPeer.Send(json.encode({
                                action = "opcoords",
                                x = pData.playablePosition.x,
                                y = pData.playablePosition.y
                            }))
                            o.lastPositionSendTime = GetGameTimer()
                        end
                    end

                    local ballDistance = #(pData.playablePosition - o.ballData.playablePosition)
                    if ballDistance < 0.2 then
                        if not s_Session.closeToBallTime then
                            s_Session.closeToBallTime = GetGameTimer()
                        end

                    elseif s_Session.closeToBallTime then
                        s_Session.closeToBallTime = nil
                    end
                else
                    pData.playablePosition = Vector2Lerp(pData.playablePosition, pData.remotePosition,
                        (pData.moveSpeed * 1.5) * delta)

                    local displayPosition = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading,
                        pData.playablePosition.x, pData.playablePosition.y, o.playerZ)

                    SetEntityCoordsNoOffset(o.playableObjects[i + 1], displayPosition)
                end
            end
        end

        o.lastMovementUpdate = gT

        if o.ballData.pendingStates and #o.ballData.pendingStates > 0 then
            local jitterWindowMs = 250
            table.sort(o.ballData.pendingStates, function(a, b)
                return a.t < b.t
            end)
            for i = 1, #o.ballData.pendingStates do
                local pendingState = o.ballData.pendingStates[i]
                if pendingState.t > (o.lastRemoteHitTime - jitterWindowMs) then
                    o.ballData.touched = true
                    o.ballData.playablePosition = pendingState.playablePosition
                    o.ballData.velocity = pendingState.velocity
                    o.ballData.hitOrigin = s_Session.localSide == 1 and 2 or 1
                    o.ballData.lastPlayer = s_Session.localSide == 1 and 2 or 1
                    o.ballData.enemyHitTime = GetSyncedGameTimer()
                    o.lastRemoteHitTime = math.max(o.lastRemoteHitTime, pendingState.t)
                    if pendingState.saved then
                        s_Session.shotsOnNet = s_Session.shotsOnNet + 1
                        -- PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS")
                        PlaySoundFrontend(-1, "Checkpoint_Teammate", "GTAO_Shepherd_Sounds")
                        AnimpostfxPlay("HeistLocate", 1000)
                        s_Session.opSaves = s_Session.opSaves + 1
                        Stats_Increase("rcore_airhockey_shoots_on_net", 1)
                        SendToJavascript("SavesChanged", s_Session.opponentServerId, s_Session.opSaves)
                    end
                end
            end
            o.ballData.pendingStates = {}
        end

        -- handle side change & draw penalty bar
        local ballSide = o.ballData.playablePosition.y < 0.0 and 1 or 2
        local mySide = s_Session.localSide == ballSide

        if o.ballData.actualSide ~= ballSide then
            o.ballData.actualSide = ballSide
            o.ballData.sideChangedTime = GetSyncedGameTimer()
            o.toggleTicking(false)
        end

        if not o.ballData.touched then
            o.ballData.sideChangedTime = GetSyncedGameTimer()
        end

        local sideChangedAgo = GetSyncedGameTimer() - o.ballData.sideChangedTime
        if mySide and not s_Session.sideTicking and sideChangedAgo > Config.PenaltyTime / 3.0 then
            o.toggleTicking(true)
        end

        if s_tickingBar then
            local percentage = sideChangedAgo * 1.0 / Config.PenaltyTime
            s_tickingBar.setProgress(percentage)
            TimerBar.DrawAll()

            if percentage >= 1 then
                o.ballData.sideChangedTime = GetSyncedGameTimer()
                o.onGoalTrigger(o.ballData.actualSide)
            end
        end

        -- keep the ball on table
        if o.ballData.playablePosition.x < o.playableMinBall.x then
            o.ballData.playablePosition = vector2(o.playableMinBall.x, o.ballData.playablePosition.y)
            o.ballData.velocity = vector2(math.abs(o.ballData.velocity.x), o.ballData.velocity.y)
            o.ballData.hitOrigin = 3
            for i = 1, 2, 1 do
                o.playerData[i].hitsAgo = o.playerData[i].hitsAgo + 1
            end
            SendToJavascript("PlayPuckSound")
        end

        if o.ballData.playablePosition.x > o.playableMaxBall.x then
            o.ballData.playablePosition = vector2(o.playableMaxBall.x, o.ballData.playablePosition.y)
            o.ballData.velocity = vector2(-math.abs(o.ballData.velocity.x), o.ballData.velocity.y)
            o.ballData.hitOrigin = 3
            for i = 1, 2, 1 do
                o.playerData[i].hitsAgo = o.playerData[i].hitsAgo + 1
            end
            SendToJavascript("PlayPuckSound")
        end

        if o.ballData.playablePosition.y < o.playableMinBall.y then
            -- check for goals on the left
            local towardsGoal = o.ballData.velocity.y < 0.0
            if towardsGoal and o.ballData.playablePosition.x >= -0.13 and o.ballData.playablePosition.x <= 0.13 then
                o.onGoalTrigger(1)
            else
                o.ballData.playablePosition = vector2(o.ballData.playablePosition.x, o.playableMinBall.y)
                o.ballData.velocity = vector2(o.ballData.velocity.x, math.abs(o.ballData.velocity.y))
                o.ballData.hitOrigin = 3
                for i = 1, 2, 1 do
                    o.playerData[i].hitsAgo = o.playerData[i].hitsAgo + 1
                end
                SendToJavascript("PlayPuckSound")
            end
        end

        if o.ballData.playablePosition.y > o.playableMaxBall.y then
            -- check for goals on the left
            local towardsGoal = o.ballData.velocity.y > 0.0
            if towardsGoal and o.ballData.playablePosition.x >= -0.13 and o.ballData.playablePosition.x <= 0.13 then
                o.onGoalTrigger(2)
            else
                o.ballData.playablePosition = vector2(o.ballData.playablePosition.x, o.playableMaxBall.y)
                o.ballData.velocity = vector2(o.ballData.velocity.x, -math.abs(o.ballData.velocity.y))
                o.ballData.hitOrigin = 3
                for i = 1, 2, 1 do
                    o.playerData[i].hitsAgo = o.playerData[i].hitsAgo + 1
                end
                SendToJavascript("PlayPuckSound")
            end
        end

        -- slow down a bit for lag compensation (clamped to avoid negative speeds)
        local simulateSpeed = 1.0
        if o.ballData.lastPlayer == s_Session.localSide and o.ballData.actualSide ~= s_Session.localSide then
            local ping = s_Session.ping or 0
            local clampedPing = math.min(ping, 600)
            simulateSpeed = 1.0 - (clampedPing / 2000.0)
            simulateSpeed = Clamp(simulateSpeed, 0.7, 1.0)
        end

        -- calculate new ball position from velocity + framerate
        local newBallPosition = vector2(o.ballData.playablePosition.x + (o.ballData.velocity.x * delta * simulateSpeed),
            o.ballData.playablePosition.y + (o.ballData.velocity.y * delta * simulateSpeed))

        local ballTravel = #(o.ballData.playablePosition - newBallPosition)
        s_Session.ballTravelDistance = s_Session.ballTravelDistance + ballTravel

        o.ballData.playablePosition = newBallPosition

        local displayPosition = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, o.ballData.playablePosition.x,
            o.ballData.playablePosition.y, o.ballZ)

        SetEntityCoordsNoOffset(o.playableObjects[1], displayPosition)

        if s_Session.playerMovement then
            local wasHit = false

            for i = 1, 2, 1 do
                local pDatas = o.playerData[i]
                if i == s_Session.localSide or s_Session.isAI then
                    if not wasHit then
                        if CircleCollision(o.ballData, pDatas) then
                            local continue = true

                            if everyoneClose then
                                if pDatas.closeHitsAllowed > 0 then
                                    pDatas.closeHitsAllowed = pDatas.closeHitsAllowed - 1
                                    if pDatas.closeHitsAllowed == 0 then
                                        SetEntityAlpha(o.playableObjects[i + 1], 50, true)
                                        pDatas.currentAlpha = 50
                                    end
                                else
                                    continue = false
                                end
                            end

                            if continue then
                                o.ballData.touched = true
                                o.lastBallHit = GetSyncedGameTimer()
                                local wasSave = false

                                if i ~= s_Session.localSide then
                                    o.ballData.enemyHitTime = GetGameTimer()
                                end

                                if i == s_Session.localSide or s_Session.isAI then
                                    local ballGoingToNet = 0
                                    local ballVelY = o.ballData.velocity.y
                                    local ballTowardsSide =
                                        math.abs(ballVelY) > 0.0001 and (ballVelY > 0.0 and 2 or 1) or 0

                                    if o.ballData.hitOrigin ~= i and ballTowardsSide == i and
                                        o.IsPuckGoingTowardsNet(ballTowardsSide) then
                                        ballGoingToNet = ballTowardsSide
                                        o.needSave = {
                                            time = GetSyncedGameTimer(),
                                            fromSide = i
                                        }
                                    else
                                        if o.needSave then
                                            local timeSinceNeed = GetSyncedGameTimer() - o.needSave.time
                                            if not o.IsPuckGoingTowardsNet(o.needSave.fromSide) then
                                                local opId = i == 1 and 2 or 1
                                                if o.playerData[opId].hitsAgo <= 4 and timeSinceNeed < 100 then
                                                    if o.playerData[i].netId == 0 then
                                                        o.aiSaveCount = (o.aiSaveCount or 0) + 1
                                                    end
                                                    wasSave = i
                                                end
                                                o.needSave = nil
                                            elseif timeSinceNeed >= 2000 then
                                                o.needSave = nil
                                            end
                                        end
                                    end
                                end

                                CreateBallCounce(o.ballData, pDatas, everyoneClose, s_Session.settings.ballSpeed)

                                local velNormal = Vector2Normalized(o.ballData.velocity)
                                local strength = velNormal.x * velNormal.y

                                o.shakeCamera(vector2(velNormal.x, -velNormal.y), strength * Config.BounceStrength)

                                if wasSave and (wasSave == s_Session.localSide or s_Session.isAI) then
                                    -- PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS")
                                    PlaySoundFrontend(-1, "Checkpoint_Teammate", "GTAO_Shepherd_Sounds")
                                    AnimpostfxPlay("HeistLocate", 1000)
                                    if wasSave == s_Session.localSide then
                                        s_Session.saves = s_Session.saves + 1
                                        Stats_Increase("rcore_airhockey_shoots_saves", 1)
                                    else
                                        s_Session.opSaves = s_Session.opSaves + 1
                                        Stats_Increase("rcore_airhockey_shoots_on_net", 1)
                                    end
                                    SendToJavascript("SavesChanged", o.playerData[wasSave].netId, wasSave ==
                                        s_Session.localSide and s_Session.saves or o.aiSaveCount)
                                end

                                local hitMsg = {
                                    action = "phit",
                                    x = o.ballData.playablePosition.x,
                                    y = o.ballData.playablePosition.y,
                                    vx = o.ballData.velocity.x,
                                    vy = o.ballData.velocity.y,
                                    px = pDatas.playablePosition.x,
                                    py = pDatas.playablePosition.y,
                                    s = o.ballData.allowSound,
                                    saved = wasSave,
                                    t = GetSyncedGameTimer()
                                }

                                if not s_Session.isAI then
                                    opponentPeer.Send(json.encode(hitMsg))
                                end

                                o.ballData.hitOrigin = i
                                o.ballData.lastPlayer = i
                                for pi = 1, 2, 1 do
                                    if pi == i then
                                        o.playerData[pi].hitsAgo = 0
                                    else
                                        o.playerData[pi].hitsAgo = o.playerData[pi].hitsAgo + 1
                                    end
                                end
                                if o.ballData.allowSound then
                                    o.ballData.allowSound = false
                                    SendToJavascript("PlayPaddleSound")
                                end
                            end

                            wasHit = true
                        end
                    end
                end
            end
            if not wasHit then
                o.ballData.allowSound = true
            end
        end
    end

    o.summonObjectAtCoords = function(id, coords)
        local obj = o.playableObjects[id]
        local worldPos = coords
        if id == 1 then
            o.ballData.playablePosition = worldPos
            SetObjectTextureVariant(obj, o.ballData.skin - 1)
            worldPos = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, coords.x, coords.y, o.ballZ)
        else
            coords = o.playerSpawns[coords]
            local pData = o.playerData[id - 1]
            pData.summonMouseCoords = vector2(coords[1], coords[2])
            local x = Lerp(o.playableMin.x, o.playableMax.x, coords[2])
            local y = Lerp(o.playableMin.y, o.playableMax.y, coords[1])
            worldPos = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, x, y, o.playerZ)
            pData.playablePosition = vector2(x, y)
            pData.remotePosition = pData.playablePosition
            SetObjectTextureVariant(obj, pData.skin - 1)
        end
        CreateThread(function()
            local a = 0
            local lastFrame = GetGameTimer()
            local startCoords = worldPos + vector3(0.0, 0.0, 0.1)
            while a < 1 do
                local delta = (GetGameTimer() - lastFrame) / 100
                a = a + (delta * 0.4)
                local actualPos = Vector2Lerp(startCoords, worldPos, a)
                SetEntityCoordsNoOffset(obj, actualPos)
                lastFrame = GetGameTimer()
                Wait(0)
            end
        end)
    end

    o.highlightLocalPlayer = function()
        if not s_Session then
            return
        end
        CreateThread(function()
            local t = GetSyncedGameTimer() + 5000
            local pdata = o.playerData[s_Session.localSide]
            local color = MarkerColors[pdata.skin] or MarkerColors[1]
            while GetSyncedGameTimer() < t and s_Session and not s_Session.playerMovement do
                local markerCoords = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, pdata.playablePosition.x,
                    pdata.playablePosition.y, o.playerZ - 0.0358)
                DrawMarker(27, markerCoords.x, markerCoords.y, markerCoords.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3,
                    color[1], color[2], color[3], 100, 0, 0, 2, true, 0, 0, false)
                Wait(0)
            end
        end)
    end

    o.startAiming = function()
        SetNuiFocus(false, true)
        if o.isAiming then
            return
        end
        o.isAiming = true
        CreateThread(function()
            o.lastMovementUpdate = GetGameTimer()
            o.lastPositionSendTime = GetGameTimer()
            local pData = o.playerData[s_Session.localSide]
            while o.isAiming and s_Session and not s_Session.finished and o.subscribed and o.playableObjects[1] and
                DoesEntityExist(o.playableObjects[1]) do
                local mouseX, mouseY = o.getDeltaFromMouse()
                -- keep paddles on their sides of the table
                -- stay away from the center more if not using peerjs (fewer desync issues)
                local minx = s_Session.localSide == 1 and 0.0 or (o.useFivem and 0.63 or 0.55)
                local maxx = s_Session.localSide == 1 and (o.useFivem and 0.37 or 0.45) or 1.0
                mouseX = Clamp(mouseX, minx, maxx)
                pData.position = vector2(mouseX, mouseY) + pData.velocity
                o.handleMovement()
                -- light up the table at night
                if GetClockHours() > 20 then
                    DrawLightWithRange(o.tableCoords.x, o.tableCoords.y, o.tableCoords.z + 1.0, 255, 255, 255, 5.0, 0.5)
                end
                Wait(0)
            end
            o.isAiming = false
        end)
    end

    o.stopAiming = function()
        o.isAiming = false
    end

    o.shakeCamera = function(direction, strength)
        if o.shaking then
            return
        end
        o.shaking = true
        CreateThread(function()
            local lastFrame = GetGameTimer()
            local rot = vector3(-90.0, 0.0, o.tableHeading + 90.0)
            local elapsed = 0

            while o.camera do
                local delta = (GetGameTimer() - lastFrame) / 100
                elapsed = elapsed + delta

                if elapsed < 1 then
                    rot = rot + vector3(direction.x * strength, direction.y * strength, 0)
                elseif elapsed < 2 then
                    rot = rot - vector3(direction.x * strength, direction.y * strength, 0)
                else
                    break
                end

                SetCamRot(o.camera, rot, 2)
                lastFrame = GetGameTimer()
                Wait(0)
            end
            SetCamRot(o.camera, vector3(-90.0, 0.0, o.tableHeading + 90.0))
            o.shaking = false
        end)
    end

    -- enable gameplay camera (while playing)
    o.enableCamera = function()
        -- do return end
        DoScreenFadeOut(500)
        Wait(500)
        o.disableCamera()

        -- calculate fov from resolution
        local rx, ry = GetActiveScreenResolution()
        local res = ry / rx
        local fov = 96.0 + (10 * res)
        local cameraOffset = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, -0.00, 1.35)

        o.camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cameraOffset, -90.0, 0.0, o.tableHeading + 90.0, fov)
        SetCamActive(o.camera, true)
        SetCamFov(o.camera, fov)
        RenderScriptCams(true, false)
        DoScreenFadeIn(500)
    end

    -- enable ending camera (while leaving)
    o.enableFinalCamera = function(side)
        o.disableCamera()

        local camPos = GetObjectOffsetFromCoords(o.tableCoords, o.tableHeading, 0.0, side == 1 and -3.79 or 3.79, 1.31)
        local fadeDir = side == 1 and -1 or 1
        CreateThread(function()
            o.camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camPos, 0.0, 0.0,
                o.tableHeading + (side == 1 and 0.0 or 180.0), 60.0)
            SetCamActive(o.camera, true)
            SetCamFov(o.camera, 60.0)
            RenderScriptCams(true, false)

            local t = GetGameTimer() + 4000
            while GetGameTimer() < t do
                camPos = camPos + vector3(0.0, fadeDir * 0.001, 0.0)
                SetCamCoord(o.camera, camPos)
                Wait(0)
            end
            o.disableCamera()
        end)
    end

    -- destroy used camera
    o.disableCamera = function()
        if o.camera then
            SetCamActive(o.camera, false)
            DestroyCam(o.camera, false)
            RenderScriptCams(false, false)
            o.camera = nil
        end
    end

    -- toggle subscription state (seeing the table, for receiving events)
    o.toggleSubscription = function(toggle)
        if o.subscribed ~= toggle then
            o.subscribed = toggle
            TriggerServerEvent("AirHockey:Subscription", o.tableCoords, o.tableHeading, o.subscribed)
            if not toggle then
                o.isAiming = false
                o.players = nil
                o.watcherView = false
                o.replayActive = false
                o.replayToken = (o.replayToken or 0) + 1
                o.lastReplayPack = 0
                o.deletePlayableObjects()
                o.deleteReplayObjects()
            end
        end
    end

    -- toggle nearby state (standing close to table)
    o.toggleNearBy = function(toggle)
        if o.nearBy ~= toggle then
            o.nearBy = toggle
            TriggerServerEvent("AirHockey:ToggleNearby", o.tableCoords, o.tableHeading, toggle)
        end
    end

    o.playableMin = vector2(-0.454, -0.919)
    o.playableMax = vector2(0.453, 0.918)
    o.playableMinBall = vector2(-0.475, -0.940)
    o.playableMaxBall = vector2(0.473, 0.940)
    o.ballZ = 0.8186
    o.playerZ = 0.8186 + 0.024
    o.playerSpawns = {{0.0913, 0.179}, {0.0913, 0.821}, {0.9028, 0.179}, {0.9028, 0.821}}

    o.resetPositions()
    return o
end
