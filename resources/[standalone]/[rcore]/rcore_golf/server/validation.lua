local function ConfigWarning(message)
    print("^1[WARNING] " .. message .. "^7")
end

local function ValidatePar(holeId, holeData)
    if not holeData.par then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have a par set! This will cause errors. ")
        return
    end

    if holeData.par <= 2 or holeData.par >= 9 then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " seems to have a par that is too high or low! Par is " .. holeData.par)
    end
end

local function ValidateMapAngle(holeId, holeData)
    if not holeData.mapAngle then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have a mapAngle set! This will cause errors. ")
        return
    end

    if holeData.mapAngle <= 40 or holeData.mapAngle >= 300 then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " seems to have a par that is too high or low! mapAngle is " .. holeData.mapAngle)
    end
end

local function ValidateCoordsForHole(holeId, coords, coordType)
    if not coords then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have " .. coordType .. " set!. This will cause errors.")
        return
    end

    if type(coords) ~= "vector3" then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .." " .. coordType .. " is not a vector3. This will cause errors.")
    end
end

local function ValidateBounds(holeId, holeData)
    if not holeData.bounds then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the bounds set! This will cause errors. ")
        return
    end

    if type(holeData.bounds) ~= "table" then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the bounds set as a table! This will cause errors. ")
        return
    end

    for _, boundData in pairs(holeData.bounds) do
        if not boundData[1] then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the bound coords set. This will cause errors.")
        elseif type(boundData[1]) ~= "vector3" then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the bound coords set as a vector3. This will cause errors.")
        end

        if not boundData[2] then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the bound radius set. This will cause errors.")
        elseif type(boundData[2]) ~= "number" then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the bound radius set as a number. This will cause errors.")
        end
    end
end

local function ValidateTerrainGrid(holeId, holeData)
    if not holeData.terrainGrid then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the terrain grid set! This will cause errors.")
        return
    end

    if type(holeData.terrainGrid) ~= "table" then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the terrain grid set as a table! This will cause errors.")
        return
    end

    for terrainIndex, terrainData in pairs(holeData.terrainGrid) do
        if terrainIndex ~= "gridRes" then
            if type(terrainData) ~= "vector3" then
                ConfigWarning("HOLE ID: " .. tostring(holeId) .." " .. terrainIndex .. " is not a vector3. This will cause errors.")
            end
        else
            if type(terrainData) ~= "number" then
                ConfigWarning("HOLE ID: " .. tostring(holeId) .." " .. terrainIndex .. " is not a number. This will cause errors.")
            end
        end
    end
end

local function ValidateMap(holeId, holeData)
    if not holeData.map then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the map set! This will cause errors. ")
        return
    end

    if type(holeData.map) ~= "table" then
        ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the map set as a table! This will cause errors. ")
        return
    end

    for mapIndex, mapData in pairs(holeData.map) do
        if not mapData.pos then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the " .. mapIndex .. " map pos coords set. This will cause errors.")
        elseif type(mapData.pos) ~= "vector2" then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the " .. mapIndex .. " map pos set as a vector3. This will cause errors.")
        end

        if not mapData.zoom then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the " .. mapIndex .. " map zoom set. This will cause errors.")
        elseif type(mapData.zoom) ~= "number" then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " does not have the " .. mapIndex .. " map zoom set as a number. This will cause errors.")
        end
    end
end

local function ValidateHoles(holesConfig)
    for holeId, holeData in pairs(holesConfig) do
        if not holeData or type(holeData) ~= "table" then
            ConfigWarning("HOLE ID: " .. tostring(holeId) .. " is not setup as a table. This will cause major errors.")
        else
            ValidatePar(holeId, holeData)
            ValidateMapAngle(holeId, holeData)
            ValidateCoordsForHole(holeId, holeData.holeCoords, "holeCoords")
            ValidateCoordsForHole(holeId, holeData.teeCoords, "teeCoords")
            ValidateBounds(holeId, holeData)
            ValidateTerrainGrid(holeId, holeData)
            ValidateMap(holeId, holeData)
        end
    end
end

local function ValidateKeys()
    for keyIndex, keyValue in pairs(Config.Keys) do
        if keyIndex == "openLobbyKey" then
            if type(keyValue) ~= "string" then
                ConfigWarning("KEY ID: " .. keyIndex .. " is not a string. This will cause errors.")
            end
        else
            if type(keyValue) ~= "number" then
                ConfigWarning("KEY ID: " .. keyIndex .. " is not a number. This will cause errors.")
            end
        end
    end
end

local function ValidateTexts()
    for textIndex, textValue in pairs(Texts) do
        if type(textValue) ~= "string" then
            ConfigWarning("TEXT ID: " .. textIndex .. " is not a string. This will cause errors.")
        end
    end
end

local function ValidateLobbyCoords(lobbyCoords)
    if not lobbyCoords then
        ConfigWarning("Lobby coords are not set. This will cause errors.")
        return
    end

    if type(lobbyCoords) ~= "vector3" then
        ConfigWarning("Lobby coords are not set as a vector3. This will cause errors.")
        return
    end
end

local function ValidateMainBounds(mainBounds)
    for boundIndex, boundData in pairs(mainBounds) do
        if not boundData[1] then
            ConfigWarning("MAIN BOUNDS: " .. tostring(boundIndex) .. " does not have the bound coords set. This will cause errors.")
        elseif type(boundData[1]) ~= "vector3" then
            ConfigWarning("MAIN BOUNDS: " .. tostring(boundIndex) .. " does not have the bound coords set as a vector3. This will cause errors.")
        end

        if not boundData[2] then
            ConfigWarning("MAIN BOUNDS: " .. tostring(boundIndex) .. " does not have the bound radius set. This will cause errors.")
        elseif type(boundData[2]) ~= "number" then
            ConfigWarning("MAIN BOUNDS: " .. tostring(boundIndex) .. " does not have the bound radius set as a number. This will cause errors.")
        end
    end
end

local function ValidateWindEffect()
    if not Config.WindEffect then
        ConfigWarning("Wind effect is not set. This will cause errors")
        return
    end

    if type(Config.WindEffect) ~= "number" then
        ConfigWarning("Wind effect is not set as a number. This will cause errors")
        return
    end

    if Config.WindEffect < 0.0 then
        ConfigWarning("Wind effect should not be lower than 0.0")
    end
end

local function ValidateReplaySendDelay()
    if not Config.ReplaySendDelay then
        ConfigWarning("ReplaySendDelay is not set. This will cause errors")
        return
    end

    if type(Config.ReplaySendDelay) ~= "number" then
        ConfigWarning("ReplaySendDelay is not set as a number. This will cause errors")
        return
    end

    if Config.ReplaySendDelay < 100 then
        Config.ReplaySendDelay = 100
        ConfigWarning("ReplaySendDelay should not be lower than 100 milliseconds to prevent network event spam")
        return
    end
end

local function ValidateWagerCommission()
    if not Config.HasWagerCommission then
        return
    end

    if not Config.WagerCommissionAmount then
        ConfigWarning("WagerCommissionAmount should be defined in the config if HasWagerCommission is enabled.")
        Config.HasWagerCommission = false
        return
    end

    if type(Config.WagerCommissionAmount) ~= "number" or Config.WagerCommissionAmount < 0.0 or Config.WagerCommissionAmount > 1.0 then
        ConfigWarning("WagerCommissionAmount must be a value between 0.0 and 1.0 (0% to 100%)")
        Config.HasWagerCommission = false
        return
    end
end

local function StartConfigValidation()
    for _, locationData in pairs(LocationsConfig) do
        ValidateHoles(locationData.HolesConfig)
        ValidateLobbyCoords(locationData.LobbyCoords)
        ValidateMainBounds(locationData.MainBounds)
    end
    ValidateKeys()
    ValidateTexts()
    ValidateWindEffect()
    ValidateReplaySendDelay()
    ValidateWagerCommission()
end

Citizen.CreateThread(StartConfigValidation)
