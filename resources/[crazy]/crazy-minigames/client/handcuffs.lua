-- Bottom-of-screen sweep minigame: a marker travels left to right across a
-- bar once, and the player must press E while it's inside each of the
-- three highlighted zones, in order. Pressing E outside the current
-- required zone, or letting the marker sweep past a zone without a
-- press, fails immediately and the bar turns red.
--
-- Exported for other resources to gate an action on
-- (exports['crazy-minigames']:StartHandcuffMinigame(targetServerId)).
-- Runs on the player being handcuffed, not the one cuffing them - see
-- qbx_police's police:client:GetCuffed
-- ([qbx]/qbx_police/client/interactions.lua), which calls this with
-- their own cache.serverId in place of the ox_lib skillCheck it used to
-- run there. Success there means they escaped (same "isSuccess -> don't
-- get cuffed" branch qbx_police already had), so pass true here.
--
-- Each successful escape (server-tracked, see server/handcuffs.lua)
-- speeds the bar up for their next attempt. After 3 escapes in a row,
-- the 4th attempt is an automatic fail - no minigame - they're finally
-- overpowered regardless of input.

local active = false

local ESCAPE_CAP = 3
local SPEED_MULTIPLIER_PER_ESCAPE = 0.75 -- 25% faster per prior escape
local MIN_DURATION = 1200
local BOX_WIDTH = 6 -- percent width of each actual target box

---@param bands { min: number, max: number }[] the range each box is allowed to land in
---@return { min: number, max: number }[]
local function randomizeZones(bands)
    local zones = {}
    for i, band in ipairs(bands) do
        local width = math.min(BOX_WIDTH, band.max - band.min)
        local start = band.min + math.random() * (band.max - band.min - width)
        zones[i] = { min = start, max = start + width }
    end
    return zones
end

---@param targetServerId? number the player playing the minigame, for per-player escape tracking/speedup. Omit to always run at base speed with no tracking.
---@param opts? { duration?: number, zones?: { min: number, max: number }[] } zones here are bands - a smaller box is randomized somewhere inside each one every run, not the box itself
---@return boolean success
local function StartHandcuffMinigame(targetServerId, opts)
    if active then return false end
    active = true

    local escapeCount = 0
    if targetServerId then
        local ok, result = pcall(lib.callback.await, 'crazy-minigames:server:getHandcuffEscapeCount', false, targetServerId)
        if ok and type(result) == 'number' then escapeCount = result end
    end

    if targetServerId and escapeCount >= ESCAPE_CAP then
        -- Escaped too many times in a row - overpowered this time, no
        -- chance to resist.
        TriggerServerEvent('crazy-minigames:server:resetHandcuffEscapes', targetServerId)
        active = false
        return false
    end

    opts = opts or {}
    local baseDuration = opts.duration or 4000
    local duration = math.max(MIN_DURATION, math.floor(baseDuration * (SPEED_MULTIPLIER_PER_ESCAPE ^ escapeCount)))
    local bands = opts.zones or {
        { min = 25, max = 35 },
        { min = 45, max = 60 },
        { min = 70, max = 90 },
    }
    local zones = randomizeZones(bands)

    SendNUIMessage({ game = 'handcuffs', action = 'start', duration = duration, zones = zones })

    local p = promise.new()
    local resolved = false

    local function finish(success)
        if resolved then return end
        resolved = true
        active = false

        if targetServerId then
            if success then
                TriggerServerEvent('crazy-minigames:server:handcuffEscaped', targetServerId)
            else
                TriggerServerEvent('crazy-minigames:server:resetHandcuffEscapes', targetServerId)
            end
        end

        if not success then
            PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        end

        SendNUIMessage({ game = 'handcuffs', action = success and 'success' or 'fail' })
        SetTimeout(success and 400 or 700, function()
            SendNUIMessage({ game = 'handcuffs', action = 'hide' })
        end)
        p:resolve(success)
    end

    CreateThread(function()
        local startTime = GetGameTimer()
        local hitIndex = 1

        while not resolved do
            Wait(0)

            local elapsed = GetGameTimer() - startTime
            local pct = (elapsed / duration) * 100

            if pct >= 100 then
                finish(false)
                break
            end

            local zone = zones[hitIndex]

            if IsControlJustPressed(0, 38) then -- E
                if zone and pct >= zone.min and pct <= zone.max then
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                    SendNUIMessage({ game = 'handcuffs', action = 'hitZone', index = hitIndex })
                    hitIndex += 1
                    if hitIndex > #zones then
                        finish(true)
                        break
                    end
                else
                    finish(false)
                    break
                end
            elseif zone and pct > zone.max then
                -- Swept past the zone we still needed without a press.
                finish(false)
                break
            end
        end
    end)

    return Citizen.Await(p)
end

exports('StartHandcuffMinigame', StartHandcuffMinigame)
