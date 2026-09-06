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

    -- Ground-snap instead of trusting the ped's current Z outright - dying
    -- straight out of last stand goes through here with whatever height
    -- the crawl movement (updateCrawlMovement, below) left them at, and
    -- that deliberately preserves existing Z velocity so gravity keeps
    -- working normally while crawling - meaning it's possible to still be
    -- very slightly airborne (a bump, a ledge) the instant death triggers.
    -- Resurrecting at that exact height left them floating instead of on
    -- the ground.
    local groundFound, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    local z = groundFound and groundZ or pos.z

    NetworkResurrectLocalPlayer(pos.x, pos.y, z + 0.5, heading, true, false)
    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end
end

---remove last stand mode from player.
function EndLastStand()
    TaskPlayAnim(cache.ped, LastStandDict, 'exit', 1.0, 8.0, -1, 1, -1, false, false, false)
    LaststandTime = 0
    -- updateCrawlMovement() below freezes the ped whenever nothing is being
    -- crawled toward - this is the single point both exits from last stand
    -- (revived, or bled out into death) already funnel through, so it's
    -- also the one guaranteed place to unfreeze them again.
    FreezeEntityPosition(cache.ped, false)
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
local CRAWL_WINDUP_MS = 400 -- lets the crawl pose blend in before actually sliding

-- Win32 virtual-key codes for W/A/S/D, used with IsRawKeyDown below.
local KEY_W, KEY_A, KEY_S, KEY_D = 0x57, 0x41, 0x53, 0x44

-- True on any frame WASD is actually being held down - read by
-- setdownedstate.lua's playUnescortedLastStandAnimation to pick between the
-- crawl anim and the stationary injured-idle one instead of always playing
-- the crawl pose even while standing still. Flips the instant a key is
-- pressed (so the pose itself starts blending in right away) - separate
-- from crawlWindupStarted below, which is what actually gates movement.
IsCrawling = false

-- Timestamp (GetGameTimer()) of when WASD was first pressed this "hold",
-- or nil while nothing is held. Going straight from the idle pose to
-- sliding across the ground the same instant the anim switches looked like
-- a snap - this makes the switch-to-crawling-anim and the start-of-actual-
-- movement two separate steps a beat apart, so the pose has time to blend
-- in before the ped starts moving in it.
local crawlWindupStarted = nil

-- Moves the ped directly instead of leaning on GTA's own locomotion system -
-- a real "stay down and crawl" movement needs a movement clipset built for
-- it, and this project doesn't have one that's confirmed to actually exist
-- (a wrong guess here previously broke last stand outright - see the pcall
-- comment below), and simply re-enabling movement controls let normal
-- standing locomotion take over the instant a movement key was pressed.
--
-- Reads raw keyboard state (IsRawKeyDown) rather than GTA's own control
-- system - two earlier attempts (the boolean IsDisabledControlPressed,
-- then the analog GetDisabledControlNormal against a deadzone) both kept
-- reporting these controls as held with nothing pressed, since they were
-- being read on controls this same loop force-disables every frame
-- (DisableControls() below) - raw key state bypasses GTA's control
-- mapping/disabling entirely, so it isn't affected by that. Trade-off:
-- this only recognizes keyboard WASD, not a controller's stick.
-- FreezeEntityPosition is extra insurance on top of that - the ped is
-- fully frozen (immune to gravity/physics drift, not just uncontrolled)
-- on any frame nothing is held, and only unfrozen for the instant a key
-- actually moves it.
local function updateCrawlMovement()
    local moveForward = IsRawKeyDown(KEY_W)
    local moveBack = IsRawKeyDown(KEY_S)
    local moveLeft = IsRawKeyDown(KEY_A)
    local moveRight = IsRawKeyDown(KEY_D)

    IsCrawling = moveForward or moveBack or moveLeft or moveRight

    if not IsCrawling then
        crawlWindupStarted = nil
        FreezeEntityPosition(cache.ped, true)
        return
    end

    FreezeEntityPosition(cache.ped, false)

    if not crawlWindupStarted then
        crawlWindupStarted = GetGameTimer()
    end

    local settlingIntoPose = GetGameTimer() - crawlWindupStarted < CRAWL_WINDUP_MS

    local dir = vector3(0.0, 0.0, 0.0)
    if not settlingIntoPose then
        local camHeadingRad = math.rad(GetGameplayCamRot(2).z)
        local forward = vector3(-math.sin(camHeadingRad), math.cos(camHeadingRad), 0.0)
        local right = vector3(math.cos(camHeadingRad), math.sin(camHeadingRad), 0.0)

        if moveForward then dir += forward end
        if moveBack then dir -= forward end
        if moveRight then dir += right end
        if moveLeft then dir -= right end

        if #dir ~= 0.0 then
            dir = dir / #dir -- normalize so diagonal (e.g. W+D) isn't faster than a straight direction
            -- Face the direction actually being crawled toward, not just
            -- wherever the camera points, so moving backward/sideways turns
            -- them to face it instead of sliding around while still facing
            -- the camera's forward. SetEntityHeading, not SetPedDesiredHeading -
            -- that native only takes effect through an active ped locomotion
            -- task turning toward it over time, and this ped isn't running one
            -- (movement here is direct velocity, not a task) - so it just sat
            -- there doing nothing and the crawling player's own view got stuck
            -- facing one way instead. The velocity fix a turn ago (teleport ->
            -- SetEntityVelocity) already addresses position sync, and heading
            -- syncs alongside position in the same ped-sync packet, so a plain
            -- instant heading set should now reach other players fine too.
            SetEntityHeading(cache.ped, math.deg(math.atan(-dir.x, dir.y)))
        end
    end

    -- Velocity, not a per-frame teleport (SetEntityCoordsNoOffset) - other
    -- players' clients interpolate/extrapolate a networked ped's movement
    -- from its synced velocity between position updates, not from raw
    -- position jumps, so a teleport-based crawl looked frozen on their
    -- screen until the next full sync packet caught them up all at once
    -- (the "stops, then teleports" symptom). Setting actual velocity here
    -- is what the sync system expects, so it can interpolate the same
    -- motion everyone else sees smoothly. Z is left alone (not overridden
    -- to 0) so gravity still settles them naturally over uneven ground.
    local currentZVelocity = GetEntityVelocity(cache.ped).z
    SetEntityVelocity(cache.ped, dir.x * CRAWL_SPEED, dir.y * CRAWL_SPEED, currentZVelocity)
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
            -- Movement first so IsCrawling reflects this frame's input
            -- before PlayLastStandAnimation reads it to pick an anim.
            updateCrawlMovement()
            local ok, err = pcall(PlayLastStandAnimation)
            if not ok then
                lib.print.error(('last stand animation failed: %s'):format(err))
            end
            Wait(0)
        end
        IsCrawling = false
        startLastStandLock = false
    end)
end

exports('StartLastStand', StartLastStand)
