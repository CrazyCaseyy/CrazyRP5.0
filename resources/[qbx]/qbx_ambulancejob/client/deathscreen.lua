-- NUI front-end for qbx_medical's downed/dead states (the DeathState enum
-- in qbx_medical/config/shared.lua: ALIVE / LAST_STAND / DEAD). This only
-- LISTENS to qbx_medical's existing client events and exports - it doesn't
-- own any of the underlying timers, health, animations, or the respawn
-- mechanic itself, so none of that logic is duplicated or needs to be kept
-- in sync here beyond what's read live each tick below:
--   qbx_medical:client:onPlayerLaststand  -> show the "Knocked Out" stage
--   qbx_medical:client:onPlayerDied       -> show the "Dead" stage
--   qbx_medical:client:playerRevived      -> hide (covers both a mid-laststand
--                                            revive and a post-death respawn)

local isOpen = false
local stage = nil ---@type 'laststand'|'dead'|nil

local function closeScreen()
    if not isOpen then return end
    isOpen = false
    stage = nil
    SendNUIMessage({ action = 'hide' })
end

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    isOpen = true
    stage = 'laststand'
    SendNUIMessage({ action = 'show', stage = 'laststand' })
end)

RegisterNetEvent('qbx_medical:client:onPlayerDied', function()
    isOpen = true
    stage = 'dead'
    SendNUIMessage({ action = 'show', stage = 'dead' })
end)

RegisterNetEvent('qbx_medical:client:playerRevived', function()
    closeScreen()
end)

-- Pushes the live countdown to the NUI while a stage is open. Reading
-- qbx_medical's own exports here every tick - rather than caching
-- config.deathTime/laststandReviveInterval on this side - means these
-- numbers can't drift out of sync if qbx_medical/config/client.lua's
-- values ever change. Also doubles as a safety net that hides the screen
-- if DeathState ever returns to ALIVE through some path that doesn't fire
-- playerRevived.
CreateThread(function()
    while true do
        Wait(250)
        if not isOpen then goto continue end

        if stage == 'laststand' then
            if not exports.qbx_medical:IsLaststand() then
                closeScreen()
                goto continue
            end
            SendNUIMessage({
                action = 'update',
                stage = 'laststand',
                seconds = exports.qbx_medical:GetLaststandTime(),
            })
        elseif stage == 'dead' then
            if not exports.qbx_medical:IsDead() then
                closeScreen()
                goto continue
            end
            SendNUIMessage({
                action = 'update',
                stage = 'dead',
                seconds = exports.qbx_medical:GetDeathTime(),
            })
        end

        ::continue::
    end
end)

-- ===================================================================
-- Help someone up out of "Knocked Out" via ox_target - aim at them and
-- interact directly, instead of the existing nearest-player civilian-CPR
-- hotkey flow (hospital:client:HelpPerson, above in laststand.lua). Server
-- side validates the target is actually still in last stand before
-- reviving (server/deathscreen.lua) - the canInteract check here only
-- drives whether the option is shown.
--
-- NOT a plain addGlobalPlayer on the ped entity - a raycast straight at a
-- downed player only landed on their actual capsule from certain angles
-- (the crawl animation lays the model flat, but the collision capsule
-- ox_target's raycast tests against stays the normal upright one, so most
-- of the visible body doesn't actually line up with anything hittable).
-- Instead this tracks a small sphere zone centered on whoever's currently
-- in last stand: ox_target shows a zone's options based on where your
-- crosshair's raycast actually LANDS (ground included) being within its
-- radius, not on hitting a specific entity's capsule - much more forgiving
-- of angle, and covers "their entire character model" in practice.
-- ===================================================================

-- qbx_medical/config/shared.lua's DeathState enum - LAST_STAND = 2. Read
-- as a raw replicated state-bag value rather than requiring qbx_medical's
-- shared config just for the one number.
local DEATHSTATE_LASTSTAND = 2
local DEATH_STATE_BAG = 'qbx_medical:deathState'
local DOWNED_ZONE_RADIUS = 1.5

-- Getting helped up isn't a full medical revive - reuses qbx_medical's own
-- playerRevived event for the parts that actually need its internal state
-- (DeathState back to ALIVE, ending last stand, clearing invincibility -
-- none of which qbx_medical exports directly), then immediately drops the
-- health it just set back down to a critical 10 HP (native entity health
-- is 100-200 with 100 as the "dead" floor, matching crazy-adminmenu's same
-- -100 HUD-facing scale) instead of the full heal that event normally does.
-- MarkHelpedUp (after playerRevived, which clears it as part of the normal
-- "you're revived" reset) starts a 5-minute vulnerability window - getting
-- knocked again inside it is fatal instead of another trip to last stand
-- (qbx_medical/client/dead.lua), since this wasn't a real medical fix.
RegisterNetEvent('hospital:client:HelpedUp', function()
    TriggerEvent('qbx_medical:client:playerRevived')
    SetEntityHealth(cache.ped, 110)
    exports.qbx_medical:MarkHelpedUp()
end)

local function helpTargetUp(targetId)
    if lib.progressBar({
        duration = 8000,
        position = 'bottom',
        label = 'Helping them up...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, mouse = false },
        anim = { dict = HealAnimDict, clip = HealAnim },
    })
    then
        TriggerServerEvent('hospital:server:HelpPlayerUp', targetId)
    end
end

-- serverId -> ox_target zone id, one entry per other player currently
-- known to be in last stand.
local downedZones = {}

local function removeDownedZone(targetId)
    local zoneId = downedZones[targetId]
    if not zoneId then return end
    exports.ox_target:removeZone(zoneId)
    downedZones[targetId] = nil
end

-- Re-registers the zone at the target's current position - cheap enough to
-- just remove+recreate on an interval rather than reaching into ox_target's
-- own zone table to mutate coords in place (not something it exports).
local function refreshDownedZone(targetId, ped)
    removeDownedZone(targetId)
    downedZones[targetId] = exports.ox_target:addSphereZone({
        coords = GetEntityCoords(ped),
        radius = DOWNED_ZONE_RADIUS,
        options = {
            {
                name = 'hospital:helpUp',
                icon = 'fas fa-hand-holding-medical',
                label = 'Help Them Up',
                canInteract = function()
                    return Player(targetId).state[DEATH_STATE_BAG] == DEATHSTATE_LASTSTAND
                end,
                onSelect = function()
                    helpTargetUp(targetId)
                end,
            },
        },
    })
end

-- Tracks one downed player from this client's perspective until they're no
-- longer in last stand (helped up, or died) - crawl movement is slow
-- (CRAWL_SPEED in qbx_medical/client/laststand.lua), so a half-second
-- refresh comfortably keeps the zone under them.
local function trackDownedPlayer(targetId)
    if downedZones[targetId] then return end -- already tracking

    CreateThread(function()
        while Player(targetId).state[DEATH_STATE_BAG] == DEATHSTATE_LASTSTAND do
            local player = GetPlayerFromServerId(targetId)
            local ped = player ~= -1 and GetPlayerPed(player)
            if not ped or ped == 0 or not DoesEntityExist(ped) then break end

            refreshDownedZone(targetId, ped)
            Wait(500)
        end

        removeDownedZone(targetId)
    end)
end

AddStateBagChangeHandler(DEATH_STATE_BAG, nil, function(bagName, _, value)
    -- Client-side, this returns a local player HANDLE (not a server id like
    -- the same native gives server-side) - GetPlayerServerId converts it to
    -- what Player()/TriggerServerEvent/the rest of this file actually need.
    local playerHandle = GetPlayerFromStateBagName(bagName)
    if playerHandle == 0 then return end
    local targetId = GetPlayerServerId(playerHandle)
    if targetId == 0 or targetId == cache.serverId then return end

    if value == DEATHSTATE_LASTSTAND then
        trackDownedPlayer(targetId)
    else
        removeDownedZone(targetId)
    end
end)
