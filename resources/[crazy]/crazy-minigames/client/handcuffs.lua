-- Bottom-of-screen sweep minigame: a marker travels left to right across a
-- bar once, and the player must press E while it's inside each of the
-- three highlighted zones, in order. Pressing E outside the current
-- required zone, or letting the marker sweep past a zone without a
-- press, fails immediately and the bar turns red.
--
-- Exported for other resources to gate an action on
-- (exports['crazy-minigames']:StartHandcuffMinigame(targetServerId)),
-- e.g. qbx_police's handcuffing
-- (see [qbx]/qbx_police/client/interactions.lua).
--
-- Each failed attempt against the same target (server-tracked, see
-- server/handcuffs.lua) speeds the bar up for their next attempt. After
-- 3 resisted attempts, the 4th is an automatic success - no minigame -
-- same as the suspect finally being overpowered.

local active = false

local RESIST_CAP = 3
local SPEED_MULTIPLIER_PER_RESIST = 0.75 -- 25% faster per prior resist
local MIN_DURATION = 1200

---@param targetServerId? number the player being cuffed, for per-suspect resist tracking/speedup. Omit to always run at base speed with no tracking.
---@param opts? { duration?: number, zones?: { min: number, max: number }[] }
---@return boolean success
local function StartHandcuffMinigame(targetServerId, opts)
    if active then return false end
    active = true

    local resistCount = 0
    if targetServerId then
        local ok, result = pcall(lib.callback.await, 'crazy-minigames:server:getHandcuffResistCount', false, targetServerId)
        if ok and type(result) == 'number' then resistCount = result end
    end

    if targetServerId and resistCount >= RESIST_CAP then
        -- Worn them down - this attempt succeeds automatically.
        TriggerServerEvent('crazy-minigames:server:resetHandcuffResist', targetServerId)
        active = false
        return true
    end

    opts = opts or {}
    local baseDuration = opts.duration or 4000
    local duration = math.max(MIN_DURATION, math.floor(baseDuration * (SPEED_MULTIPLIER_PER_RESIST ^ resistCount)))
    local zones = opts.zones or {
        { min = 25, max = 35 },
        { min = 45, max = 60 },
        { min = 70, max = 90 },
    }

    SendNUIMessage({ game = 'handcuffs', action = 'start', duration = duration, zones = zones })

    local p = promise.new()
    local resolved = false

    local function finish(success)
        if resolved then return end
        resolved = true
        active = false

        if targetServerId then
            if success then
                TriggerServerEvent('crazy-minigames:server:resetHandcuffResist', targetServerId)
            else
                TriggerServerEvent('crazy-minigames:server:handcuffResisted', targetServerId)
            end
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
