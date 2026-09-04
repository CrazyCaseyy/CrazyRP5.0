local isOpen = false

local function open()
    if isOpen then return end
    isOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', rewards = Config.Rewards })
end

RegisterNetEvent('crazy-caseopening:client:open', open)

RegisterNUICallback('close', function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb(1)
end)

-- Fired when they click the "Open" button in the NUI - only now does the
-- case actually get removed and the reward rolled (still not granted
-- yet, that's 'reveal' below, once the reel's actually landed).
RegisterNUICallback('rollCase', function(_, cb)
    local result = lib.callback.await('crazy-caseopening:server:roll', false)
    if not result or result.error then
        exports.qbx_core:Notify("You don't have a case to open.", 'error')
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        isOpen = false
        cb(1)
        return
    end

    SendNUIMessage({ action = 'spin', rewardId = result.rewardId, result = result })
    cb(1)
end)

-- Fired by the reel's own animation as it passes each card - see
-- html/script.js.
RegisterNUICallback('tick', function(_, cb)
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    cb(1)
end)

-- One reveal sound per rarity tier, escalating from a plain confirm blip
-- up to the full rank-up fanfare - so landing on something better
-- actually sounds better, not just a common/rare-or-better split.
local RevealSounds = {
    common = { 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    uncommon = { 'MEDAL_BRONZE', 'HUD_AWARDS' },
    rare = { 'MEDAL_SILVER', 'HUD_AWARDS' },
    epic = { 'MEDAL_GOLD', 'HUD_AWARDS' },
    legendary = { 'RANK_UP', 'HUD_AWARDS' },
}

-- Fired once the reel actually lands - this is the moment the reward
-- gets handed over server-side (crazy-caseopening:server:claim), not
-- when the roll happened.
RegisterNUICallback('reveal', function(data, cb)
    TriggerServerEvent('crazy-caseopening:server:claim')

    local sound = RevealSounds[data.rarity] or RevealSounds.common
    PlaySoundFrontend(-1, sound[1], sound[2], true)
    cb(1)
end)
