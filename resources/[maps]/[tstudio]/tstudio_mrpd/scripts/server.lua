-- PVG System: Server-side switch state management
local switchStates = {}

-- Scenario System: Track currently active scenario
local currentScenario = nil -- Stores {id, interior, entitysets}

-- PVG System: Initialize all switches to OFF position on server start
CreateThread(function()
    for _, room in pairs(Config.Rooms) do
        for _, marker in pairs(room.markers) do
            switchStates[marker.id] = false
        end
    end
    if Config.Debug then
        print("[tstudio_mrpd_scenarios] Server: Initialized all PVG switch states to OFF")
    end
end)

-- Scenario System: Handle card selection and sync to all clients
RegisterNetEvent('tstudio_mrpd_scenarios:cardSelected', function(data)
    local src = source
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] 🎯 SERVER: Player %d selected card: %s'):format(src, data.id or 'unknown'))
    end
    
    -- Find the full card config from Config.Cards
    local cardConfig = nil
    for _, card in ipairs(Config.Cards) do
        if card.id == data.id then
            cardConfig = card
            break
        end
    end
    
    if cardConfig then
        -- Store current scenario state
        currentScenario = {
            id = cardConfig.id,
            interior = cardConfig.interior,
            entitysets = cardConfig.entitysets
        }
        
        if Config.Debug then
            print(('[tstudio_mrpd_scenarios] 📋 SERVER: Broadcasting scenario %s to all clients'):format(cardConfig.id))
            if cardConfig.entitysets then
                print(('[tstudio_mrpd_scenarios] 📋 SERVER: Scenario has %d entitysets'):format(#cardConfig.entitysets))
            end
        end
        
        -- Broadcast to ALL clients (including the selector)
        TriggerClientEvent('tstudio_mrpd_scenarios:syncScenario', -1, currentScenario)
    else
        if Config.Debug then
            print(('[tstudio_mrpd_scenarios] ❌ SERVER: Card config not found for ID: %s'):format(data.id))
        end
    end
end)

-- PVG System: Handle switch toggle request from client
RegisterNetEvent('tstudio_mrpd_scenarios:toggleSwitch')
AddEventHandler('tstudio_mrpd_scenarios:toggleSwitch', function(markerId)
    local source = source
    
    -- Validate the marker ID exists
    local markerExists = false
    for _, room in pairs(Config.Rooms) do
        for _, marker in pairs(room.markers) do
            if marker.id == markerId then
                markerExists = true
                break
            end
        end
        if markerExists then break end
    end
    
    if markerExists then
        -- Toggle the switch state on server
        switchStates[markerId] = not switchStates[markerId]
        
        if Config.Debug then
            print("[tstudio_mrpd_scenarios] Server: Player " .. source .. " toggled PVG switch " .. markerId .. " to " .. (switchStates[markerId] and "ON" or "OFF"))
        end
        
        -- Broadcast the new state to all clients
        TriggerClientEvent('tstudio_mrpd_scenarios:syncSwitchState', -1, markerId, switchStates[markerId])
    else
        if Config.Debug then
            print("[tstudio_mrpd_scenarios] Server: Invalid marker ID received: " .. tostring(markerId))
        end
    end
end)

-- PVG System: Send current switch states to a newly connected player
RegisterNetEvent('tstudio_mrpd_scenarios:requestSyncStates')
AddEventHandler('tstudio_mrpd_scenarios:requestSyncStates', function()
    local source = source
    
    if Config.Debug then
        print("[tstudio_mrpd_scenarios] Server: Sending current PVG switch states to player " .. source)
    end
    
    -- Send all current switch states to the requesting client
    for markerId, state in pairs(switchStates) do
        TriggerClientEvent('tstudio_mrpd_scenarios:syncSwitchState', source, markerId, state)
    end
    
    -- Send current scenario state to the requesting client
    if currentScenario then
        if Config.Debug then
            print(('[tstudio_mrpd_scenarios] Server: Sending current scenario %s to player %d'):format(currentScenario.id, source))
        end
        TriggerClientEvent('tstudio_mrpd_scenarios:syncScenario', source, currentScenario)
    end
end)