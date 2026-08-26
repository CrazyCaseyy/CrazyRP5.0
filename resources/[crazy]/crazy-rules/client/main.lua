local isOpen = false

local function openRules()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', rules = Config.Rules })
end

local function closeRules()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('rules', openRules, false)

RegisterNUICallback('close', function(_, cb)
    closeRules()
    cb(1)
end)

RegisterNUICallback('accept', function(_, cb)
    closeRules()
    TriggerServerEvent('crazy-rules:server:accept')
    cb(1)
end)
