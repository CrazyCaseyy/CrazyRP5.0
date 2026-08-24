local config = require 'config.shared'
local activePeds = {}
local robbing = false
local robbingStoreId = nil
local cooldownWarned = {}

-- storeId -> GetGameTimer() ms before which the cashier stays gone (fled and
-- deleted after a completed robbery). Read instead of a plain "robbed" flag so
-- the ped actually comes back once the cooldown passes, rather than needing
-- the player to leave and re-enter the zone to notice.
local storeAvailableAt = {}

-- Precomputed once: comparing a dot product against a cosine is cheaper than
-- doing trig per frame, and this check runs every frame while near a store.
local MELEE_AIM_DOT = math.cos(math.rad(config.meleeAimAngle))

---Unit vector the gameplay camera is pointing along. Camera rather than ped
---forward, because the ped's body visibly lags behind where the player is
---actually looking mid-turn.
---@return vector3
local function getCameraForward()
    local rot = GetGameplayCamRot(2)
    local pitch, yaw = math.rad(rot.x), math.rad(rot.z)
    local cosPitch = math.abs(math.cos(pitch))

    return vec3(-math.sin(yaw) * cosPitch, math.cos(yaw) * cosPitch, math.sin(pitch))
end

---Whether the player is holding aim, for weapons where free-aim never reports.
---IsPlayerFreeAiming only reports for firearms; the raw control covers blades,
---and the disabled variant is checked too because other resources routinely
---disable the aim control, which silently forces IsControlPressed to false.
---@return boolean
local function isPlayerAiming()
    return IsPlayerFreeAiming(cache.playerId)
        or IsControlPressed(0, 25)
        or IsDisabledControlPressed(0, 25)
end

---How closely the camera is pointed at a ped: 1.0 is dead-on, 0.0 is 90 degrees off.
---@param delta vector3 target coords minus player coords
---@param distance number precomputed length of delta
---@return number
local function getAimDot(delta, distance)
    local dir = delta / distance
    local forward = getCameraForward()

    return forward.x * dir.x + forward.y * dir.y + forward.z * dir.z
end

---@param targetPed number
---@return boolean
local function isThreateningPed(targetPed)
    -- 7 = melee | gun | thrown, so bare fists never qualify. Checked with
    -- IsPedArmed rather than weapon-group hashes because melee covers several
    -- groups (GROUP_MELEE, GROUP_NIGHTSTICK, ...) and this collapses them all.
    if not IsPedArmed(cache.ped, 7) then return false end

    local delta = GetEntityCoords(targetPed) - GetEntityCoords(cache.ped)
    local distance = #(delta)

    if IsPedArmed(cache.ped, 1) then
        if distance > config.meleeThreatDistance or distance <= 0 then return false end

        -- A blade has no reticle to read, so "pointed at him" is the cashier
        -- sitting inside a cone in front of the camera. That alone is the real
        -- fix for a knife triggering just by being drawn nearby - holding aim
        -- on top of it is opt-in, since the aim control is unreliable while a
        -- melee weapon is equipped (the game uses it for block/guard there).
        if config.meleeRequireAim and not isPlayerAiming() then return false end

        return getAimDot(delta, distance) >= MELEE_AIM_DOT
    end

    -- Firearms: anywhere inside the radius counts, with no at-the-ped check.
    -- Resolving "aimed exactly at this entity" needs a per-frame raycast against
    -- a ped usually stood behind a counter - both unreliable and the expensive
    -- option, which is why the radius is the deliberate trade here.
    if distance > config.gunThreatDistance then return false end

    return IsPlayerFreeAiming(cache.playerId)
end

---@param store table
---@param storeId number
---@return number? ped nil if the store is still cooling down from being robbed
local function spawnCashier(store, storeId)
    if activePeds[storeId] and DoesEntityExist(activePeds[storeId]) then
        return activePeds[storeId]
    end

    local availableAt = storeAvailableAt[storeId]
    if availableAt and GetGameTimer() < availableAt then
        return nil
    end

    lib.requestModel(config.pedModel)

    local ped = CreatePed(4, config.pedModel, store.coords.x, store.coords.y, store.coords.z, store.coords.w, false, true)
    -- Invincible while frozen, not permanently - flipped to killable in
    -- finishRobberySequence at the exact moment he's unfrozen, so death is
    -- never possible while he's still locked in place.
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, true) -- so dying looks like dying, not a rigid drop
    SetPedFleeAttributes(ped, 0, false)
    SetPedDiesInstantlyInWater(ped, false)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(config.pedModel)

    activePeds[storeId] = ped
    return ped
end

---@param storeId number
local function despawnCashier(storeId)
    local ped = activePeds[storeId]
    if ped and DoesEntityExist(ped) then
        DeletePed(ped)
    end
    activePeds[storeId] = nil
end

-- Each beat is a list of candidates tried in order until one actually plays.
--
-- SHOP does not exist on this build - confirmed via the always-on warning
-- (`give cash animation did not play: SHOP / SHP_ROB_GIVECASH`), not a guess -
-- so it's left out entirely rather than kept as a first candidate. Requesting
-- a dict that will never load still costs the full timeout in
-- lib.requestAnimDict before falling through, so leaving it in would have
-- added a silent ~1.5s stall to the start of every beat below for no benefit.
--
-- Note the deliberate absence of AF_SECONDARY (16) in every flag below: a
-- secondary animation task keeps playing over any primary one started after
-- it, which is what previously hid the payout behind a pair of raised hands.
local ROBBERY_ANIM_REACT = {
    { dict = 'mp_am_hold_up', clip = 'handsup_enter', duration = -1, flag = 2 },
}

-- Held for the length of the robbery. AF_LOOPING (1), since this is a
-- purpose-built loop rather than a one-shot clip held on its last frame.
local ROBBERY_ANIM_HOLD = {
    { dict = 'mp_am_hold_up', clip = 'handsup_base', duration = -1, flag = 1 },
}

-- Handing the takings over the counter at the end of the robbery.
-- robbery_action_a closes the list because it's the one clip in this whole
-- sequence that's been confirmed working in this resource from before any of
-- the SHOP/mp_am_hold_up experimentation - if givetake1_a somehow doesn't
-- resolve either, this one will.
local ROBBERY_ANIM_GIVECASH = {
    { dict = 'mp_common', clip = 'givetake1_a', duration = -1, flag = 0 },
    { dict = 'random@shop_robbery', clip = 'robbery_action_a', duration = -1, flag = 0 },
}

-- Bumped whenever the sequence starts or stops. The sequence spans several
-- Waits, so each stage re-checks the id it captured is still current - without
-- it, a robbery cancelled mid-sequence would have its next stage start on a ped
-- that was already cleared, leaving the cashier stuck in a pose.
local animSequenceId = 0

-- Heading the cashier was placed at, so turning them toward the robber can be
-- undone when the robbery ends.
local animOriginalHeading = nil

---Starts one stage and confirms it actually took.
---
---Deliberately does NOT pre-screen with DoesAnimDictExist/GetAnimDuration.
---Predicting availability that way rejected clips that would have played
---perfectly well, and the prediction is unnecessary anyway: playing the clip
---and then asking the ped whether it is playing it answers the question
---outright. TaskPlayAnim itself reports nothing on a missing dict or clip,
---which is what made every earlier failure here silent.
---@param ped number
---@param stage table
---@return number? lengthMs how long to hold this beat, nil if it didn't play
local function playAnimStage(ped, stage)
    if not pcall(lib.requestAnimDict, stage.dict, 1500) then
        if config.debug then lib.print.warn(('anim dict would not load: %s'):format(stage.dict)) end
        return nil
    end

    TaskPlayAnim(ped, stage.dict, stage.clip, 8.0, -8.0, stage.duration, stage.flag, 0.0, false, false, false)

    -- Long enough for the task to genuinely take before checking. 50ms here
    -- previously produced false negatives on clips that were actually starting
    -- fine, which fed the next candidate on top of them mid-motion.
    Wait(150)

    if not IsEntityPlayingAnim(ped, stage.dict, stage.clip, 3) then
        if config.debug then lib.print.warn(('anim did not take: %s / %s'):format(stage.dict, stage.clip)) end
        return nil
    end

    -- Prefer the clip's real length over a guessed one - timing a beat off a
    -- guess is what made the hands-up raise finish early and visibly drop back
    -- to idle. A requested duration still caps it, since TaskPlayAnim stops
    -- there regardless of how long the clip actually runs.
    local seconds = GetAnimDuration(stage.dict, stage.clip)
    local lengthMs = seconds > 0.0 and math.floor(seconds * 1000) or stage.duration

    if stage.duration > 0 and lengthMs > stage.duration then
        lengthMs = stage.duration
    end

    return lengthMs > 0 and lengthMs or nil
end

---Plays the first candidate that resolves.
---@param ped number
---@param candidates table[]
---@param beat string label used if none of them resolve
---@return table? stage
---@return number? lengthMs
local function playFirstAvailable(ped, candidates, beat)
    for i = 1, #candidates do
        local lengthMs = playAnimStage(ped, candidates[i])

        if lengthMs then return candidates[i], lengthMs end
    end

    -- Always warned, not gated behind debug: a whole beat silently doing
    -- nothing is exactly the failure that's hard to diagnose from in-game.
    lib.print.warn(('no %s animation resolved out of %d candidates - the cashier will skip that beat')
        :format(beat, #candidates))

    return nil, nil
end

---@param ped number
local function playRobberyAnim(ped)
    animSequenceId += 1
    local sequenceId = animSequenceId

    -- The clerk turns to face whoever's robbing them, like they do in GTA
    -- Online. The ped is frozen in place, so its heading is set directly - a
    -- turn task would just be ignored.
    local pedCoords = GetEntityCoords(ped)
    local playerCoords = GetEntityCoords(cache.ped)

    animOriginalHeading = GetEntityHeading(ped)
    SetEntityHeading(ped, GetHeadingFromVector_2d(playerCoords.x - pedCoords.x, playerCoords.y - pedCoords.y))

    -- Threaded: the reaction has to finish before the hold starts, and
    -- startRobbery needs to reach its progress bar immediately, not wait on it.
    CreateThread(function()
        local _, reactMs = playFirstAvailable(ped, ROBBERY_ANIM_REACT, 'react')

        -- Cut over slightly early so the hold blends straight out of the
        -- reaction rather than after it, which leaves a visible drop.
        if reactMs then Wait(math.floor(reactMs * 0.75)) end

        if sequenceId ~= animSequenceId or not DoesEntityExist(ped) then return end

        -- Held for the whole robbery - the progress bar runs far longer than
        -- any single clip.
        playFirstAvailable(ped, ROBBERY_ANIM_HOLD, 'hands up')
    end)
end

---@param ped number
local function stopRobberyAnim(ped)
    animSequenceId += 1 -- invalidates any sequence still in flight

    if DoesEntityExist(ped) then
        ClearPedTasks(ped)

        if animOriginalHeading then
            SetEntityHeading(ped, animOriginalHeading)
        end
    end

    animOriginalHeading = nil
end

---Cashier hands the takings over the counter, then is let go: unfrozen and
---sent fleeing. The robbery isn't reported to the server, and the cooldown
---doesn't start, until this animation actually finishes - not merely when the
---progress bar fills - so a robbery that visibly hasn't paid out yet can't
---already be handing out rewards or blocking a re-attempt.
---
---Blocking rather than fired-and-forgotten: the previous version ran this in
---its own thread while startRobbery moved on and cleared `robbing` in the same
---tick, so a threat-check on the very next frame could race a robbery that was
---still mid-payout, which is what made the hold pose look like it never let go.
---@param storeId number
---@param ped number
local function finishRobberySequence(storeId, ped)
    animSequenceId += 1 -- takes the ped off the hands-up hold
    local sequenceId = animSequenceId

    -- Clear the held pose first. A held clip left running can sit over the top
    -- of whatever starts next, which is what previously masked the payout.
    ClearPedTasks(ped)
    Wait(0)

    if sequenceId == animSequenceId and DoesEntityExist(ped) then
        -- Fallback timing keeps this paced even if no candidate plays, so the
        -- sequence can't collapse into a single frame.
        local _, giveMs = playFirstAvailable(ped, ROBBERY_ANIM_GIVECASH, 'give cash')
        Wait(giveMs or 3600)
    end

    TriggerServerEvent('crazy-storerobbery:server:finishRobbery', storeId)
    storeAvailableAt[storeId] = GetGameTimer() + config.cooldown

    if not DoesEntityExist(ped) then return end

    -- Let him go - unfrozen and killable together, at the same moment, rather
    -- than invincibility being lifted separately/later.
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    TaskSmartFleePed(ped, cache.ped, 100.0, -1, false, false)

    -- One timer covers both outcomes - still fleeing or shot dead along the
    -- way makes no difference, he's gone once this runs out either way.
    SetTimeout(config.despawnAfterRobbery, function()
        if DoesEntityExist(ped) then DeletePed(ped) end
        if activePeds[storeId] == ped then activePeds[storeId] = nil end
    end)
end

---Cancels the robbery once the player is config.cancelDistance from the
---cashier - the only way out now that the progress bar's own cancel key is
---disabled (see startRobbery). Bound to lib.progressActive() rather than its
---own sequence id, so it can't outlive the robbery it's watching or fire
---lib.cancelProgress() a second time after the bar's already ended.
---@param ped number
local function watchCancelDistance(ped)
    CreateThread(function()
        while lib.progressActive() do
            if #(GetEntityCoords(cache.ped) - GetEntityCoords(ped)) > config.cancelDistance then
                lib.cancelProgress()
                return
            end

            Wait(500)
        end
    end)
end

---@param storeId number
---@param ped number
local function startRobbery(storeId, ped)
    if robbing then return end

    local canRob = lib.callback.await('crazy-storerobbery:server:canRob', false, storeId)
    if not canRob then
        if not cooldownWarned[storeId] then
            cooldownWarned[storeId] = true
            exports.qbx_core:Notify(locale('notify.cooldown'), 'error')
        end
        return
    end

    robbing = true
    robbingStoreId = storeId
    playRobberyAnim(ped)

    -- Fired at the start, not on success - a dispatch alert that only shows up once the
    -- robbery is already over isn't something police can actually respond to.
    exports['ps-dispatch']:CustomAlert({
        dispatchCode = 'storerobbery', -- matches Config.Blips.storerobbery in ps-dispatch for icon/sound
        message = 'Store Robbery in Progress',
        code = '10-90',
        icon = 'fas fa-cash-register',
        coords = GetEntityCoords(ped),
        jobs = { 'leo' },
    })

    -- Once started, keep going regardless of aim/weapon state - canCancel is off, so the
    -- player's own cancel key does nothing here. The only way out is watchCancelDistance
    -- below actually calling lib.cancelProgress() once they're config.cancelDistance away.
    watchCancelDistance(ped)

    if lib.progressBar({
        duration = config.duration,
        label = locale('text.robbing'),
        position = 'bottom',
        canCancel = false,
        disable = {
            car = true,
        },
    }) then
        -- Blocking: `robbing` has to stay true for the whole payout, not just
        -- the 60s bar, or a threat-check on the next frame can fire on a
        -- cashier that's still mid-animation (see finishRobberySequence).
        finishRobberySequence(storeId, ped)
    else
        TriggerServerEvent('crazy-storerobbery:server:cancelRobbery', storeId)
        stopRobberyAnim(ped)
    end

    robbing = false
    robbingStoreId = nil
end

local activeSafes = {}
local safeAvailableAt = {}
local crackingSafe = false

---Cancels the in-progress robbery once the player is config.vault.cancelDistance
---from the safe - mirrors watchCancelDistance for the register robbery above.
---@param safeCoords vector3
local function watchVaultCancelDistance(safeCoords)
    CreateThread(function()
        while lib.progressActive() do
            if #(GetEntityCoords(cache.ped) - safeCoords) > config.vault.cancelDistance then
                lib.cancelProgress()
                return
            end

            Wait(250)
        end
    end)
end

---@param storeId number
---@param safeCoords vector3
local function crackSafe(storeId, safeCoords)
    if crackingSafe or robbing then return end

    local canRob, reason = lib.callback.await('crazy-storerobbery:server:canRobVault', false, storeId)
    if not canRob then
        exports.qbx_core:Notify(locale(reason == 'locked' and 'notify.vault_locked' or 'notify.cooldown'), 'error')
        return
    end

    crackingSafe = true

    -- Fired at the start, same as the register - a heist that's already over
    -- by the time police get the alert isn't one they can respond to.
    exports['ps-dispatch']:CustomAlert({
        dispatchCode = 'storerobbery',
        message = 'Safe Cracking in Progress',
        code = '10-90',
        icon = 'fas fa-vault',
        coords = safeCoords,
        jobs = { 'leo' },
    })

    watchVaultCancelDistance(safeCoords)

    local success = lib.progressBar({
        duration = config.vault.duration,
        label = locale('text.cracking'),
        position = 'bottom',
        canCancel = false,
        disable = {
            move = true,
            car = true,
        },
        anim = config.vault.anim,
    })

    if success then
        TriggerServerEvent('crazy-storerobbery:server:finishVault', storeId)
        safeAvailableAt[storeId] = GetGameTimer() + config.vault.cooldown
    else
        TriggerServerEvent('crazy-storerobbery:server:failVault', storeId)
        exports.qbx_core:Notify(locale('notify.vault_failed'), 'error')
    end

    crackingSafe = false
end

---@param store table
---@param storeId number
local function setupSafeZone(store, storeId)
    if not store.safe or activeSafes[storeId] then return end

    activeSafes[storeId] = true

    -- No prop spawned - this sits on the cabinet the store's own map model
    -- already has at this spot, not something crazy-storerobbery adds.
    exports.ox_target:addBoxZone({
        coords = store.safe,
        size = vec3(1.0, 1.0, 1.5),
        options = {
            {
                name = ('crazy-storerobbery:vault:%s'):format(storeId),
                label = locale('target.crack_safe'),
                icon = 'fa-solid fa-vault',
                distance = 1.5,
                canInteract = function()
                    if crackingSafe or robbing then return false end
                    local availableAt = safeAvailableAt[storeId]
                    return not (availableAt and GetGameTimer() < availableAt)
                end,
                onSelect = function() crackSafe(storeId, store.safe) end,
            },
        },
    })
end

local function setupStores()
    for i, store in ipairs(config.stores) do
        setupSafeZone(store, i)

        local point = lib.points.new({
            coords = store.coords.xyz,
            distance = 25,
            storeId = i,
        })

        function point:onEnter()
            spawnCashier(store, self.storeId)
        end

        function point:onExit()
            -- Leaving this 25m zone no longer cancels an active robbery on
            -- its own - watchCancelDistance (config.cancelDistance, 50m from
            -- the cashier specifically) is what actually governs that now.
            if not robbing then
                despawnCashier(self.storeId)
            end
        end

        function point:nearby()
            if robbing then return end

            -- Store's on cooldown - skip even bothering to look for a ped.
            -- Also catches the few seconds after a robbery where the cashier
            -- still technically exists but is fleeing, which isn't someone to
            -- run a fresh threat-check against.
            local availableAt = storeAvailableAt[self.storeId]
            if availableAt and GetGameTimer() < availableAt then return end

            local ped = activePeds[self.storeId]
            if not ped or not DoesEntityExist(ped) then
                -- No-ops until storeAvailableAt has actually passed - this is
                -- what makes the cashier reappear on their own once the store
                -- is robbable again, without needing the player to leave and
                -- re-enter the zone.
                spawnCashier(store, self.storeId)
                return
            end

            if not isThreateningPed(ped) then
                cooldownWarned[self.storeId] = false
                return
            end

            startRobbery(self.storeId, ped)
        end
    end
end

CreateThread(setupStores)

-- Reports which melee gate is currently failing, since a silent no-trigger
-- otherwise gives nothing to go on. Costs nothing when the flag is off.
if config.debug then
    CreateThread(function()
        while true do
            Wait(500)

            if not robbing then
                for storeId, ped in pairs(activePeds) do
                    if DoesEntityExist(ped) then
                        local delta = GetEntityCoords(ped) - GetEntityCoords(cache.ped)
                        local distance = #(delta)
                        local dot = distance > 0 and getAimDot(delta, distance) or 0.0

                        print(('[crazy-storerobbery] store %s | melee=%s aiming=%s dist=%.2f/%.2f cone=%.3f/%.3f')
                            :format(storeId, IsPedArmed(cache.ped, 1), isPlayerAiming(),
                                distance, config.meleeThreatDistance, dot, MELEE_AIM_DOT))
                    end
                end
            end
        end
    end)
end
