local isOpen = false

-- PVG System: Track switch states for each marker (true = ON position, false = OFF position)
local switchStates = {}

local function SetUIVisible(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ type = 'setVisible', visible = state })
end

-- PVG System: Initialize entity sets on resource start
CreateThread(function()
    -- Load IPLs and set initial states for each room
    for _, room in pairs(Config.Rooms) do
        -- Request IPL for the room
        RequestIpl(room.ipl)
        
        -- Initialize switch states for each marker in the room
        for _, marker in pairs(room.markers) do
            -- Initialize switch to OFF position (false)
            switchStates[marker.id] = false
        end
    end
    
    -- Wait a moment for server to be ready, then request current states
    Wait(1000)
    TriggerServerEvent('tstudio_mrpd_scenarios:requestSyncStates')
    
    if Config.Debug then
        print("[tstudio_mrpd_scenarios] Entity sets initialized for all rooms - requesting server sync")
    end
end)

-- Disable controls when NUI is open
CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true)  -- LookLeftRight
            DisableControlAction(0, 2, true)  -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAlternate
            DisableControlAction(0, 18, true)  -- Enter
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 200, true) -- ESC (Pause)
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(_, cb)
    SetUIVisible(false)
    cb({ ok = true })
end)

RegisterNUICallback('requestCards', function(_, cb)
    -- Send cards from config to NUI
    SendNUIMessage({ 
        type = 'setCards', 
        cards = Config.Cards 
    })
    cb({ ok = true })
end)

-- Scenario System: Function to apply scenario entity sets
function ApplyScenarioEntitySets(scenarioData)
    if not scenarioData then
        if Config.Debug then
            print('[tstudio_mrpd_scenarios] No scenario data provided')
        end
        return
    end
    
    -- First, disable ALL entitysets from ALL cards to ensure clean state
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] Disabling all entitysets from other cards...'))
    end
    for _, card in ipairs(Config.Cards) do
        if card.entitysets and #card.entitysets > 0 and card.interior then
            local interiorCoords = type(card.interior) == "string" and vector3(0, 0, 0) or card.interior
            if type(card.interior) == "string" then
                -- If interior is a string, try to find coordinates from rooms
                for _, room in pairs(Config.Rooms) do
                    if room.roomCoords then
                        interiorCoords = room.roomCoords
                        break
                    end
                end
            end
            
            local interiorID = GetInteriorAtCoords(interiorCoords.x, interiorCoords.y, interiorCoords.z)
            if IsValidInterior(interiorID) then
                for _, entitysetName in ipairs(card.entitysets) do
                    DeactivateInteriorEntitySet(interiorID, entitysetName)
                    if Config.Debug then
                        print(('[tstudio_mrpd_scenarios] ✅ Deactivated entityset: %s in interior ID: %d (from card: %s)'):format(entitysetName, interiorID, card.id))
                    end
                end
                RefreshInterior(interiorID)
            end
        end
    end
    
    -- Now enable entitysets for the selected scenario
    if scenarioData.entitysets and #scenarioData.entitysets > 0 and scenarioData.interior then
        if Config.Debug then
            print(('[tstudio_mrpd_scenarios] Enabling %d entitysets for scenario: %s'):format(#scenarioData.entitysets, scenarioData.id))
        end
        
        local interiorCoords = type(scenarioData.interior) == "string" and vector3(0, 0, 0) or scenarioData.interior
        if type(scenarioData.interior) == "string" then
            -- If interior is a string, try to find coordinates from rooms
            for _, room in pairs(Config.Rooms) do
                if room.roomCoords then
                    interiorCoords = room.roomCoords
                    break
                end
            end
        end
        
        local interiorID = GetInteriorAtCoords(interiorCoords.x, interiorCoords.y, interiorCoords.z)
        if IsValidInterior(interiorID) then
            for i, entitysetName in ipairs(scenarioData.entitysets) do
                if Config.Debug then
                    print(('[tstudio_mrpd_scenarios] Entityset %d: interior ID: %d, entityset: %s'):format(i, interiorID, entitysetName))
                end
                
                -- Activate entityset for selected scenario
                ActivateInteriorEntitySet(interiorID, entitysetName)
                if Config.Debug then
                    print(('[tstudio_mrpd_scenarios] ✅ Activated entityset: %s in interior ID: %d'):format(entitysetName, interiorID))
                end
            end
            RefreshInterior(interiorID)
        else
            if Config.Debug then
                print(('[tstudio_mrpd_scenarios] ❌ Interior not found or invalid for: %s'):format(scenarioData.interior))
            end
        end
    else
        if Config.Debug then
            print(('[tstudio_mrpd_scenarios] No entitysets defined for scenario: %s'):format(scenarioData.id))
        end
    end
end

RegisterNUICallback('selectCard', function(data, cb)
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] Select button clicked! Card ID: %s'):format(data.id or 'unknown'))
    end
    
    -- Find the card config to get interior info
    local cardConfig = nil
    for _, card in ipairs(Config.Cards) do
        if card.id == data.id then
            cardConfig = card
            break
        end
    end
    
    if not cardConfig then
        if Config.Debug then
            print(('[tstudio_mrpd_scenarios] ❌ Card config not found for ID: %s'):format(data.id))
        end
        cb({ ok = false, error = 'Card not found' })
        return
    end
    
    -- Trigger server event - server will broadcast to all clients
    TriggerServerEvent('tstudio_mrpd_scenarios:cardSelected', data)
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] Server event triggered for card: %s - waiting for sync'):format(data.id))
    end
    
    -- Close UI after selection
    SetUIVisible(false)
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] UI closed after card selection'))
    end
    cb({ ok = true })
end)

-- Open UI command (also used from interaction)
RegisterNetEvent('tstudio_mrpd_scenarios:openUI', function()
    if not isOpen then
        -- Send cards data when opening UI
        SendNUIMessage({ 
            type = 'setCards', 
            cards = Config.Cards 
        })
        SetUIVisible(true)
    end
end)

-- PVG System: Main marker and interaction thread
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        
        -- Find closest marker distance for dynamic sleep optimization
        local closestDist = 999999.9
        for _, room in pairs(Config.Rooms) do
            for _, marker in pairs(room.markers) do
                local distance = #(coords - marker.coords)
                if distance < closestDist then
                    closestDist = distance
                end
            end
        end
        
        -- Dynamic sleep based on closest marker
        if closestDist < 10.0 then
            sleep = 0 -- Near markers, check every frame
        elseif closestDist < 25.0 then
            sleep = 250 -- Medium distance, check 4x per second
        else
            -- Far from all markers, sleep and skip processing
            Wait(sleep)
            goto continue
        end
        
        -- Process markers (only when close enough)
        for _, room in pairs(Config.Rooms) do
            for _, marker in pairs(room.markers) do
                local distance = #(coords - marker.coords)
                
                -- Draw marker if player is within draw distance
                if distance < Config.MarkerSettings.drawDistance then
                    DrawMarker(
                        Config.MarkerSettings.type,
                        marker.coords.x, marker.coords.y, marker.coords.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.MarkerSettings.scale.x, Config.MarkerSettings.scale.y, Config.MarkerSettings.scale.z,
                        marker.color.r, marker.color.g, marker.color.b, marker.color.a,
                        false, true, 2, false, nil, nil, false
                    )
                    
                    -- Check for interaction
                    if distance < Config.MarkerSettings.interactionDistance then
                        -- Display help text with current switch state
                        local switchState = switchStates[marker.id] and "ON" or "OFF"
                        local nextState = switchStates[marker.id] and "OFF" or "ON"
                        SetTextComponentFormat("STRING")
                        AddTextComponentString("Press ~INPUT_CONTEXT~ to turn " .. marker.name .. " " .. nextState .. " (Currently: " .. switchState .. ")")
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                        
                        -- Handle interaction
                        if IsControlJustPressed(0, 38) then -- E key
                            TogglePVGMarkerSwitch(room, marker)
                        end
                    end
                end
            end
        end
        
        ::continue::
        Wait(sleep)
    end
end)

-- PVG System: Function to toggle switch for a specific marker
function TogglePVGMarkerSwitch(room, marker)
    -- Send request to server to toggle the switch
    TriggerServerEvent('tstudio_mrpd_scenarios:toggleSwitch', marker.id)
end

-- PVG System: Function to apply switch state to entity sets
function ApplyPVGSwitchState(markerId, state)
    -- Find the marker and room by ID
    local targetRoom, targetMarker = nil, nil
    for _, room in pairs(Config.Rooms) do
        for _, marker in pairs(room.markers) do
            if marker.id == markerId then
                targetRoom = room
                targetMarker = marker
                break
            end
        end
        if targetMarker then break end
    end
    
    if not targetMarker or not targetRoom then
        if Config.Debug then
            print("[tstudio_mrpd_scenarios] Error: Marker not found for ID: " .. markerId)
        end
        return
    end
    
    local interior = GetInteriorAtCoords(targetRoom.roomCoords.x, targetRoom.roomCoords.y, targetRoom.roomCoords.z)
    
    if interior ~= 0 then
        if state then
            -- Switch to ON position: activate ON entities, deactivate OFF entities
            for _, entitySetName in pairs(targetMarker.entitySetsOn) do
                ActivateInteriorEntitySet(interior, entitySetName)
                if Config.Debug then
                    print("[tstudio_mrpd_scenarios] PVG Activated: " .. entitySetName)
                end
            end
            for _, entitySetName in pairs(targetMarker.entitySetsOff) do
                DeactivateInteriorEntitySet(interior, entitySetName)
                if Config.Debug then
                    print("[tstudio_mrpd_scenarios] PVG Deactivated: " .. entitySetName)
                end
            end
        else
            -- Switch to OFF position: activate OFF entities, deactivate ON entities
            for _, entitySetName in pairs(targetMarker.entitySetsOff) do
                ActivateInteriorEntitySet(interior, entitySetName)
                if Config.Debug then
                    print("[tstudio_mrpd_scenarios] PVG Activated: " .. entitySetName)
                end
            end
            for _, entitySetName in pairs(targetMarker.entitySetsOn) do
                DeactivateInteriorEntitySet(interior, entitySetName)
                if Config.Debug then
                    print("[tstudio_mrpd_scenarios] PVG Deactivated: " .. entitySetName)
                end
            end
        end
        
        RefreshInterior(interior)
    else
        if Config.Debug then
            print("[tstudio_mrpd_scenarios] Interior not found for room: " .. targetRoom.name)
        end
    end
end

-- PVG System: Network event to receive switch state updates from server
RegisterNetEvent('tstudio_mrpd_scenarios:syncSwitchState')
AddEventHandler('tstudio_mrpd_scenarios:syncSwitchState', function(markerId, state)
    -- Update local state
    switchStates[markerId] = state
    
    -- Apply the state to entity sets
    ApplyPVGSwitchState(markerId, state)
    
    if Config.Debug then
        print("[tstudio_mrpd_scenarios] Synced switch " .. markerId .. " to " .. (state and "ON" or "OFF"))
    end
end)

-- Scenario System: Network event to receive scenario updates from server
RegisterNetEvent('tstudio_mrpd_scenarios:syncScenario')
AddEventHandler('tstudio_mrpd_scenarios:syncScenario', function(scenarioData)
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] 🔄 Received scenario sync from server: %s'):format(scenarioData.id))
    end
    
    -- Apply the scenario entity sets
    ApplyScenarioEntitySets(scenarioData)
    
    if Config.Debug then
        print(('[tstudio_mrpd_scenarios] ✅ Scenario %s synced and applied'):format(scenarioData.id))
    end
end)

-- UI Blip & interaction
CreateThread(function()
    -- Blip removed - no map marker

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local dist = #(pcoords - Config.UIBlip.coords)
        
        -- Dynamic sleep based on distance
        if dist < (Config.UIBlip.drawDistance or 25.0) then
            sleep = 0
            -- Use same marker style as PVG system
            DrawMarker(
                Config.UIBlip.markerType or Config.MarkerSettings.type,
                Config.UIBlip.coords.x, Config.UIBlip.coords.y, Config.UIBlip.coords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                Config.UIBlip.markerScale.x, Config.UIBlip.markerScale.y, Config.UIBlip.markerScale.z,
                Config.UIBlip.markerColor.r, Config.UIBlip.markerColor.g, Config.UIBlip.markerColor.b, Config.UIBlip.markerColor.a,
                false, true, 2, false, nil, nil, false
            )
            
            if dist < (Config.UIBlip.interactDist or 1.5) then
                -- Show interaction text
                SetTextComponentFormat("STRING")
                AddTextComponentString("Press ~INPUT_CONTEXT~ to open " .. Config.UIBlip.name)
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                
                -- 38 = E key
                if IsControlJustReleased(0, Config.UIBlip.interactKey or 38) then
                    TriggerEvent('tstudio_mrpd_scenarios:openUI')
                end
            end
        elseif dist < 50.0 then
            sleep = 500 -- Medium distance
        end
        
        Wait(sleep)
    end
end)
