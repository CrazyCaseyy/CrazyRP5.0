local config = require 'config.client'
local sharedConfig = require 'config.shared'
local WEAPONS = exports.qbx_core:GetWeapons()

---blocks until ped is no longer moving
function WaitForPlayerToStopMoving()
    local timeOut = 10000
    while GetEntitySpeed(cache.ped) > 0.1 and IsPedRagdoll(cache.ped) and timeOut > 1 do
        timeOut -= 10 Wait(10)
    end
end

--- low level GTA resurrection
function ResurrectPlayer()
    local pos = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z + 0.5, heading, true, false)
    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end
end

---remove last stand mode from player.
function EndLastStand()
    TaskPlayAnim(cache.ped, LastStandDict, 'exit', 1.0, 8.0, -1, 1, -1, false, false, false)
    LaststandTime = 0
    TriggerServerEvent('qbx_medical:server:onPlayerLaststandEnd')
end

local function logPlayerKiller()
    local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(cache.playerId)
    local killer = GetPedSourceOfDeath(cache.ped)

    if killer_2 ~= 0 and killer_2 ~= -1 then
        killer = killer_2
    end

    local killerId = NetworkGetPlayerIndexFromPed(killer)
    local killerName = killerId ~= -1 and (' %s (%d)'):format(GetPlayerName(killerId), GetPlayerServerId(killerId)) or locale('info.self_death')
    local weaponItem = WEAPONS[killerWeapon]
    local weaponLabel = locale('info.wep_unknown') or (weaponItem and weaponItem.label)
    local weaponName = locale('info.wep_unknown') or (weaponItem and weaponItem.name)
    local message = locale('logs.death_log_message', killerName, GetPlayerName(cache.playerId), weaponLabel, weaponName)

    lib.callback.await('qbx_medical:server:log', false, 'playerKiller', message)
end

---count down last stand, if last stand is over, put player in death mode and log the killer.
local function countdownLastStand()
    if LaststandTime - 1 > 0 then
        LaststandTime -= 1
    else
        exports.qbx_core:Notify(locale('error.bled_out'), 'error')
        EndLastStand()
        logPlayerKiller()
        DeathTime = config.deathTime
        OnDeath()
    end
end

local startLastStandLock = false

local CRAWL_SPEED = 0.65 -- ground units/second while dragging themselves forward

-- Moves the ped directly instead of leaning on GTA's own locomotion system -
-- a real "stay down and crawl" movement needs a movement clipset built for
-- it, and this project doesn't have one that's confirmed to actually exist
-- (a wrong guess here previously broke last stand outright - see the pcall
-- comment below), and simply re-enabling movement controls let normal
-- standing locomotion take over the instant a movement key was pressed.
-- This instead keeps every control disabled (so GTA's own movement never
-- engages, and the crawl anim in setdownedstate.lua never gets interrupted)
-- and only drags the ped when one of WASD is actually held, in whatever
-- direction that key means relative to wherever the camera is currently
-- facing - matching normal on-foot movement's camera-relative feel.
--
-- Reads GetDisabledControlNormal (an actual 0.0-1.0 press magnitude)
-- against a small deadzone rather than the boolean IsDisabledControlPressed -
-- that boolean was reporting these controls as held even with nothing
-- pressed, moving the ped on its own. The numeric read is the standard,
-- more reliable way to poll input on a control that's deliberately being
-- kept disabled.
local MOVE_DEADZONE = 0.1

local function updateCrawlMovement()
    local forwardAmount = GetDisabledControlNormal(0, 32) -- INPUT_MOVE_UP_ONLY (W)
    local backAmount = GetDisabledControlNormal(0, 33) -- INPUT_MOVE_DOWN_ONLY (S)
    local leftAmount = GetDisabledControlNormal(0, 34) -- INPUT_MOVE_LEFT_ONLY (A)
    local rightAmount = GetDisabledControlNormal(0, 35) -- INPUT_MOVE_RIGHT_ONLY (D)

    if forwardAmount < MOVE_DEADZONE and backAmount < MOVE_DEADZONE
        and leftAmount < MOVE_DEADZONE and rightAmount < MOVE_DEADZONE then
        return
    end

    local camHeadingRad = math.rad(GetGameplayCamRot(2).z)
    local forward = vector3(-math.sin(camHeadingRad), math.cos(camHeadingRad), 0.0)
    local right = vector3(math.cos(camHeadingRad), math.sin(camHeadingRad), 0.0)

    local dir = vector3(0.0, 0.0, 0.0)
    if forwardAmount >= MOVE_DEADZONE then dir += forward end
    if backAmount >= MOVE_DEADZONE then dir -= forward end
    if rightAmount >= MOVE_DEADZONE then dir += right end
    if leftAmount >= MOVE_DEADZONE then dir -= right end

    if #dir == 0.0 then return end -- opposing keys held together (e.g. W+S) cancel out

    dir = dir / #dir -- normalize so diagonal (e.g. W+D) isn't faster than a straight direction

    local coords = GetEntityCoords(cache.ped)
    local newCoords = coords + dir * (CRAWL_SPEED * GetFrameTime())

    -- Face the direction actually being crawled toward, not just wherever
    -- the camera points, so moving backward/sideways turns them to face it
    -- instead of sliding around while still facing the camera's forward.
    SetEntityHeading(cache.ped, math.deg(math.atan(-dir.x, dir.y)))
    SetEntityCoordsNoOffset(cache.ped, newCoords.x, newCoords.y, newCoords.z, true, true, true)
end

---put player in last stand mode and notify EMS.
function StartLastStand(attacker, weapon)
    if startLastStandLock then return end
    startLastStandLock = true
    TriggerEvent('ox_inventory:disarm', cache.playerId, true)
    WaitForPlayerToStopMoving()
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'demo', 0.1)
    LaststandTime = config.laststandReviveInterval
    ResurrectPlayer()
    SetEntityHealth(cache.ped, 150)
    SetDeathState(sharedConfig.deathState.LAST_STAND)
    TriggerEvent('qbx_medical:client:onPlayerLaststand', attacker, weapon)
    TriggerServerEvent('qbx_medical:server:onPlayerLaststand', attacker, weapon)
    CreateThread(function()
        while DeathState == sharedConfig.deathState.LAST_STAND do
            countdownLastStand()
            Wait(1000)
        end
    end)

    CreateThread(function()
        -- pcall guards against a bad LastStandDict/LastStandAnim (set in
        -- main.lua) throwing mid-loop - an uncaught error here used to abort
        -- this whole thread before it reached `startLastStandLock = false`
        -- below, which permanently no-op'd every future StartLastStand()
        -- call (players would just ragdoll like vanilla GTA from then on,
        -- since the `if startLastStandLock then return end` guard above
        -- returns immediately while the lock is stuck true). Now a bad
        -- anim just skips its own frame instead of breaking the feature
        -- for the rest of the session.
        while DeathState == sharedConfig.deathState.LAST_STAND do
            DisableControls()
            local ok, err = pcall(PlayLastStandAnimation)
            if not ok then
                lib.print.error(('last stand animation failed: %s'):format(err))
            end
            updateCrawlMovement()
            Wait(0)
        end
        startLastStandLock = false
    end)
end

exports('StartLastStand', StartLastStand)
