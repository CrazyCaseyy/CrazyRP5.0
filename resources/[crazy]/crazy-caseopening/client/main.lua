local isOpen = false

local function open()
    if isOpen then return end
    isOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', rewards = Config.Rewards })

    -- Removing the item and rolling the reward both happen server-side,
    -- inside this callback - the NUI is already open and showing the
    -- idle case by the time this resolves, then gets told what to spin
    -- to.
    local result = lib.callback.await('crazy-caseopening:server:open', false)
    if not result or result.error then
        exports.qbx_core:Notify("You don't have a case to open.", 'error')
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        isOpen = false
        return
    end

    SendNUIMessage({ action = 'spin', rewardId = result.rewardId, result = result })
end

RegisterNetEvent('crazy-caseopening:client:open', open)

RegisterNUICallback('close', function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb(1)
end)

-- Fired by the reel's own animation as it passes each card, and once
-- more when it lands - see html/script.js.
RegisterNUICallback('tick', function(_, cb)
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    cb(1)
end)

RegisterNUICallback('reveal', function(data, cb)
    if data.rarity == 'epic' or data.rarity == 'legendary' then
        PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', true)
    else
        PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
    cb(1)
end)
