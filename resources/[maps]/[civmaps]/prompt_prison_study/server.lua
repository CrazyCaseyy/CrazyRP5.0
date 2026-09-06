local entitySets = {}
local clientData = {}
local haveOxLib = GetResourceState('ox_lib') == 'started'
local config
local animCoreResourceName
local animCoreType -- 'new' for prompt_anim_core_2_*, 'old' for prompt_anim_core

-- Load config
if haveOxLib then
    config = require 'config'
else
    local configFile = LoadResourceFile(GetCurrentResourceName(), 'config.lua')
    if configFile then
        local configFunc, err = load(configFile, '@@' .. GetCurrentResourceName() .. '/config.lua')
        if configFunc then
            config = configFunc()
        else
            print('^1[prison_gym] Failed to load config: ' .. tostring(err) .. '^0')
            config = {}
        end
    else
        print('^1[prison_gym] Failed to read config.lua file^0')
        config = {}
    end
    print('^3[prison_gym] ox_lib not found, some features may be disabled.^0')
end

-- Debug print helper
local function debugPrint(...)
    if config.Debug then
        print('[prison_gym]', ...)
    end
end

-- Deep clone helper
local function deepClone(original)
    if haveOxLib then
        return lib.table.deepclone(original)
    end
    local copy
    if type(original) == 'table' then
        copy = {}
        for k, v in pairs(original) do
            copy[deepClone(k)] = deepClone(v)
        end
    else
        copy = original
    end
    return copy
end

-- Helper function to safely call exports with retry
local function safeExportCall(resourceName, exportName, maxRetries, ...)
    maxRetries = maxRetries or 5
    local args = {...}
    
    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            return exports[resourceName][exportName](table.unpack(args))
        end)
        
        if success then
            return true, result
        else
            debugPrint(string.format('Export call failed (attempt %d/%d): %s', attempt, maxRetries, tostring(result)))
            if attempt < maxRetries then
                Wait(1000)
            end
        end
    end
    
    return false, nil
end

-- Initialize props for NEW anim core (prompt_anim_core_2_*)
local function initializePropsNewCore()
    for name, data in pairs(config.GymLocations) do
        if not data.enabled then
            goto continue
        end
        
        local props = deepClone(data.props or {})
        
        -- Add entity set props if enabled
        if data.entitySets and data.entitySetProps then
            for entitySetName, isEnabled in pairs(data.entitySets) do
                if isEnabled and data.entitySetProps[entitySetName] then
                    for k, v in pairs(data.entitySetProps[entitySetName]) do
                        if not props[k] then
                            props[k] = {}
                        end
                        for i = 1, #v do
                            props[k][#props[k] + 1] = v[i]
                        end
                    end
                end
            end
        end

        -- Build the location data table
        local locationData = {
            coords = data.coords,
            renderDistance = data.renderDistance,
            props = props,
        }
        
        -- Debug: Print what we're sending
        debugPrint(string.format('Creating location "%s" with coords type: %s', name, type(data.coords)))
        if data.coords then
            debugPrint(string.format('Coords: %s', tostring(data.coords)))
        else
            debugPrint('WARNING: coords is nil!')
        end
        debugPrint(string.format('locationData type: %s', type(locationData)))
        
        -- Try to create the gym location with retries
        local success = false
        for attempt = 1, 5 do
            local ok, result = pcall(function()
                return exports[animCoreResourceName]:CreateGymLocation(name, locationData)
            end)
            
            if ok then
                success = true
                debugPrint('Created gym location: ' .. name .. ' with new anim core')
                break
            else
                debugPrint(string.format('CreateGymLocation failed (attempt %d/5): %s', attempt, tostring(result)))
                if attempt < 5 then
                    Wait(1000)
                end
            end
        end
        
        if not success then
            print('^1[prison_gym] Failed to create gym location: ' .. name .. '^0')
        end
        ::continue::
    end
end

-- Initialize props for OLD anim core (prompt_anim_core)
local function initializePropsOldCore()
    for name, data in pairs(config.GymLocations) do
        if not data.enabled then
            goto continue
        end
        
        -- Add entity set props if enabled
        if data.entitySets and data.entitySetProps then
            for entitySetName, isEnabled in pairs(data.entitySets) do
                if isEnabled and data.entitySetProps[entitySetName] then
                    for equipType, coordsList in pairs(data.entitySetProps[entitySetName]) do
                        -- Skip bench for old anim core (doesn't support it)
                        if equipType == 'bench' then
                            debugPrint('Skipping bench for old anim core (not supported)')
                            goto skip_equipment
                        end
                        
                        for i, coords in ipairs(coordsList) do
                            local instanceName = string.format('%s_%s_%s_%d', name, entitySetName, equipType, i)
                            local spawnCoords = coords
                            local heading = 0.0
                            
                            -- Handle vec4 format (check for .w property instead of type())
                            if coords.w then
                                spawnCoords = vec3(coords.x, coords.y, coords.z)
                                heading = coords.w
                            elseif coords.x and coords.y and coords.z then
                                -- It's already vec3 or table with x,y,z
                                spawnCoords = vec3(coords.x, coords.y, coords.z)
                            end
                            
                            -- Debug: Print what we're sending
                            debugPrint(string.format('Calling SpawnGymEquipment: equipType=%s, coords=%s, heading=%.2f, location=%s, instance=%s',
                                tostring(equipType), tostring(spawnCoords), heading, name, instanceName))
                            
                            -- Call export directly without wrapper to ensure correct argument order
                            local success, result = pcall(function()
                                return exports[animCoreResourceName]:SpawnGymEquipment(
                                    equipType,
                                    spawnCoords,
                                    heading,
                                    name,
                                    instanceName
                                )
                            end)
                            
                            if success and result then
                                debugPrint('Spawned equipment: ' .. instanceName .. ' with old anim core')
                            else
                                debugPrint('Failed to spawn equipment: ' .. instanceName .. ' - ' .. tostring(result))
                            end
                        end
                        ::skip_equipment::
                    end
                end
            end
        end
        ::continue::
    end
end

-- Detect and initialize animation core
CreateThread(function()
    -- Wait a bit for other resources to fully initialize
    Wait(3000)
    
    -- First try to find prompt_anim_core_2_* (new version)
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and string.sub(resourceName, 1, 18) == 'prompt_anim_core_2' then
            if GetResourceState(resourceName) == 'started' then
                animCoreResourceName = resourceName
                animCoreType = 'new'
                break
            end
        end
    end
    
    -- If not found, try prompt_anim_core (old version)
    if not animCoreResourceName then
        local oldCoreState = GetResourceState('prompt_anim_core')
        if oldCoreState == 'started' then
            animCoreResourceName = 'prompt_anim_core'
            animCoreType = 'old'
        else
            local limitedState = GetResourceState('prompt_anim_core_limited')
            if limitedState == 'started' then
                animCoreResourceName = 'prompt_anim_core_limited'
                animCoreType = 'old'
            end
        end
    end
    
    if animCoreResourceName then
        debugPrint('Found anim core resource: ' .. animCoreResourceName .. ' (type: ' .. animCoreType .. ')')
        
        -- Wait additional time for exports to be fully registered
        Wait(2000)
        
        if animCoreType == 'new' then
            initializePropsNewCore()
        else
            initializePropsOldCore()
        end
    else
        debugPrint('No anim core resource found. Using entity sets only (static mode).')
    end
end)

-- Initialize entity sets via GlobalState (clients react via StateBagChangeHandler)
CreateThread(function()
    Wait(1000) -- Wait for config to be ready
    
    local prisonGymEntitySets = {}
    
    for location, data in pairs(config.GymLocations) do
        if data.enabled and data.entitySets then
            entitySets[location] = data.entitySets
            clientData[data.coords] = data.entitySets
            prisonGymEntitySets[location] = data.entitySets
        end
    end
    
    -- Set GlobalState - clients will react via AddStateBagChangeHandler
    GlobalState.prisonGymEntitySets = prisonGymEntitySets
    debugPrint('GlobalState.prisonGymEntitySets initialized')
end)

-- Handle entity set requests from clients (fallback)
RegisterNetEvent('prison_gym:requestEntitySets', function()
    -- Re-set GlobalState to trigger StateBagChangeHandler for this client
    if GlobalState.prisonGymEntitySets then
        local temp = GlobalState.prisonGymEntitySets
        GlobalState.prisonGymEntitySets = temp
    end
end)

-- Handle resource restart
AddEventHandler('onResourceStart', function(resource)
    if animCoreResourceName and resource == animCoreResourceName then
        Wait(1000)
        if animCoreType == 'new' then
            initializePropsNewCore()
        else
            initializePropsOldCore()
        end
    end
end)

-- Toggle entity set function (for admin menu)
---@param location string The gym location name
---@param entitySet string The entity set name
---@param enable boolean Whether to enable or disable the entity set
---@return boolean?, string? -- true if successful, error message otherwise
local function toggleEntitySet(location, entitySet, enable)
    if not config.GymLocations[location] then
        return false, 'Invalid gym location.'
    end

    if config.GymLocations[location].entitySets[entitySet] == nil then
        return false, 'Invalid entity set for this location.'
    end

    entitySets[location][entitySet] = enable

    -- Update GlobalState (triggers StateBagChangeHandler on clients)
    local prisonGymEntitySets = GlobalState.prisonGymEntitySets or {}
    if not prisonGymEntitySets[location] then
        prisonGymEntitySets[location] = {}
    end
    prisonGymEntitySets[location][entitySet] = enable
    GlobalState.prisonGymEntitySets = prisonGymEntitySets

    -- Handle equipment spawning/despawning based on anim core type
    if animCoreResourceName then
        local entitySetProps = config.GymLocations[location].entitySetProps[entitySet]
        if entitySetProps then
            if animCoreType == 'new' then
                if enable then
                    for k, v in pairs(entitySetProps) do
                        safeExportCall(animCoreResourceName, 'AddEquipmentToLocation', 3, location, k, v)
                    end
                else
                    for k, coords in pairs(entitySetProps) do
                        safeExportCall(animCoreResourceName, 'RemoveEquipmentFromLocation', 3, location, k, coords)
                    end
                end
            else
                -- Old anim core handling
                for equipType, coordsList in pairs(entitySetProps) do
                    if equipType == 'bench' then
                        goto skip_equipment
                    end
                    
                    for i, coords in ipairs(coordsList) do
                        local instanceName = string.format('%s_%s_%s_%d', location, entitySet, equipType, i)
                        
                        if enable then
                            local spawnCoords = coords
                            local heading = 0.0
                            
                            -- Handle vec4 format (check for .w property instead of type())
                            if coords.w then
                                spawnCoords = vec3(coords.x, coords.y, coords.z)
                                heading = coords.w
                            elseif coords.x and coords.y and coords.z then
                                spawnCoords = vec3(coords.x, coords.y, coords.z)
                            end
                            
                            -- Call export directly
                            pcall(function()
                                exports[animCoreResourceName]:SpawnGymEquipment(
                                    equipType,
                                    spawnCoords,
                                    heading,
                                    location,
                                    instanceName
                                )
                            end)
                        else
                            pcall(function()
                                exports[animCoreResourceName]:DespawnGymEquipment(instanceName)
                            end)
                        end
                    end
                    ::skip_equipment::
                end
            end
        end
    end

    return true
end
exports('toggleEntitySet', toggleEntitySet)

-- ox_lib features (commands, callbacks)
if haveOxLib then
    if config.gymSets.enable then
        lib.addCommand('prisongymsets', {
            help = 'Open the prison gym entity sets menu',
            params = {},
            restricted = config.gymSets.restricted or false,
        }, function(source)
            if not config.gymSets.canAccess(source) then
                config.notify(source, 'Prison Gym Sets', 'You do not have permission to access the gym sets menu.', 'error')
                return
            end

            TriggerClientEvent('prison_gym:openSetsMenu', source, entitySets)
        end)
    end

    ---@param source number The player server ID
    ---@param data {location: string, entitySet: string, enable: boolean}
    ---@return boolean
    lib.callback.register('prison_gym:toggleEntitySet', function(source, data)
        local location = data.location
        local entitySet = data.entitySet
        local enable = data.enable

        local success, message = toggleEntitySet(location, entitySet, enable)
        if not success then
            config.notify(source, 'Prison Gym Sets', message, 'error')
            return false
        end

        TriggerClientEvent('prison_gym:openSetsMenu', source, entitySets)
        return true
    end)
end

debugPrint('Prison gym server initialized')
