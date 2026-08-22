local isOpen = false

RegisterNetEvent('crazy-reputation:client:open', function()
    if isOpen then return end

    local jobs = lib.callback.await('crazy-reputation:server:getCivilianJobs', false)

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', jobs = jobs })
    exports.scully_emotemenu:playEmoteByCommand('tablet2')
end)

local function closeTablet()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    exports.scully_emotemenu:cancelEmote()
end

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb(1)
end)
