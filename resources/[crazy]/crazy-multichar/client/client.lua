-- External multicharacter screen for qbx_core. Talks to the exact same
-- server callbacks/events qbx_core's own built-in screen uses (see
-- resources/[qbx]/qbx_core/client/character.lua and server/character.lua)
-- — this resource only replaces the UI, not the character data/ownership
-- model. Requires qbx_core's config/client.lua -> useExternalCharacters =
-- true (see README).

print('^5[crazy-multichar]^7 client.lua file is executing')

local function Debug(msg)
    if Config.Debug then
        print(('^5[crazy-multichar]^7 %s'):format(msg))
    end
end

Debug('client.lua loaded and running')

local inSelect = false
local cam = nil

local function LockPlayer()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetPlayerControl(PlayerId(), false, 0)
    DisplayRadar(false)
end

local function UnlockPlayer()
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetPlayerControl(PlayerId(), true, 0)
    DisplayRadar(true)
end

local orbitActive = false

local function CreateSelectCamera()
    local c = Config.CameraPoint
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, c.x, c.y, c.z)
    PointCamAtCoord(cam, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, Config.FadeTime, true, true)

    if Config.PreviewOrbit.enabled then
        orbitActive = true
        local orbit = Config.PreviewOrbit
        local sp = Config.SpawnPoint
        local centerZ = sp.z + orbit.height
        local angle = 200.0

        CreateThread(function()
            while orbitActive and cam do
                angle = (angle + orbit.speed) % 360.0
                local rad = math.rad(angle)
                local camX = sp.x + orbit.radius * math.cos(rad)
                local camY = sp.y + orbit.radius * math.sin(rad)
                SetCamCoord(cam, camX, camY, centerZ)
                PointCamAtCoord(cam, sp.x, sp.y, centerZ)
                Wait(0)
            end
        end)
    end
end

local function DestroySelectCamera()
    orbitActive = false
    if cam then
        RenderScriptCams(false, true, Config.FadeTime, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
end

local function RequestCharacters()
    local characters, maxSlots = lib.callback.await('qbx_core:server:getCharacters', false)
    Debug(('getCharacters returned %d character(s), maxSlots=%s'):format(#(characters or {}), tostring(maxSlots)))
    SendNUIMessage({
        action = 'characters',
        characters = characters or {},
        maxSlots = maxSlots or 3
    })
end

local function SendApartmentList()
    local list = {}
    for _, a in ipairs(Config.Apartments) do
        list[#list + 1] = { id = a.id, label = a.label, blurb = a.blurb }
    end
    SendNUIMessage({ action = 'apartments', apartments = list })
end

local function FindApartment(apartmentId)
    for _, a in ipairs(Config.Apartments) do
        if a.id == apartmentId then return a end
    end
    return nil
end

local function FindSpawnLocation(locationId)
    for _, loc in ipairs(Config.SpawnLocations) do
        if loc.id == locationId then return loc end
    end
    return nil
end

-- ===================================================================
-- Live preview ped
-- Shows the player's own (frozen, invulnerable) ped in front of the
-- camera during selection, updating its model whenever a different
-- character card is highlighted. Uses qbx_core's own
-- 'qbx_core:server:getPreviewPedData' callback for a specific model hash
-- when one's on file; this is a best-effort enhancement (correct base
-- model, not a full outfit/face preview), same as qbx_core's own built-in
-- screen — it doesn't attempt to render saved clothing either.
-- ===================================================================

local currentPreviewModel = nil

local function UpdatePreviewPed(citizenId, gender)
    gender = tonumber(gender) or 0
    local model = (gender == 1) and `mp_f_freemode_01` or `mp_m_freemode_01`

    if citizenId then
        local ok, _skin, previewModel = pcall(function()
            return lib.callback.await('qbx_core:server:getPreviewPedData', false, citizenId)
        end)
        if ok and previewModel then
            model = previewModel
        end
    end

    if currentPreviewModel == model then return end
    currentPreviewModel = model

    lib.requestModel(model)
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    local sp = Config.SpawnPoint
    SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, true)
    SetEntityHeading(ped, sp.w)
    SetEntityVisible(ped, true, false)
end

-- ===================================================================
-- Spawning
-- ===================================================================

local function EndOurSelectionState()
    inSelect = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    DestroySelectCamera()
end

local function FireLoadedEvents()
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end

-- Set while an existing character is between "selected" and "actually
-- placed in the world" — waiting on the player to pick a spawn location in
-- the modal_spawn NUI. Holds the character record so the 'apartment'
-- (useSavedPosition) option has somewhere to read the saved position from.
local pendingExistingCharacter = nil

local function SendSpawnLocationList()
    local list = {}
    for _, loc in ipairs(Config.SpawnLocations) do
        list[#list + 1] = { id = loc.id, label = loc.label, blurb = loc.blurb }
    end
    SendNUIMessage({ action = 'spawnLocations', locations = list })
end

local function SpawnSelectedCharacter(charRecord, isNewCharacter)
    local charinfo = charRecord.charinfo or charRecord
    local gender = tonumber(charinfo.gender) or 0
    local model = (gender == 1) and `mp_f_freemode_01` or `mp_m_freemode_01`

    -- Existing characters pick where to spawn from Config.SpawnLocations
    -- (apartment / Legion Square / MRPD / ...) via our own modal, replacing
    -- qbx_spawn's own scaleform selector entirely — running both back to
    -- back after crazy-multichar's own apartment step was the double-picker
    -- players were seeing.
    if not isNewCharacter then
        DoScreenFadeOut(Config.FadeTime)
        while not IsScreenFadedOut() do Wait(0) end

        lib.requestModel(model)
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)

        EndOurSelectionState()
        -- Deliberately not calling UnlockPlayer()/DoScreenFadeIn yet — stays
        -- frozen/faded-out until selectSpawnLocation below actually places
        -- the player and finishes the reveal.
        pendingExistingCharacter = charRecord
        SetNuiFocus(true, true)
        SendSpawnLocationList()
        return
    end

    -- New characters whose chosen apartment maps to a real qbx_properties
    -- interior (Config.Apartments[n].interiorIndex) get an actually-owned
    -- starter apartment instead of just a cosmetic spawn point.
    -- qbx_properties:server:apartmentSelect does the DB insert (owner =
    -- the new citizenid), creates the stash, and teleports the player
    -- inside the interior shell itself — and it fires
    -- qb-clothes:client:CreateFirstCharacter on its own once that's done,
    -- so we deliberately do NOT also fire it below (see config.lua) or
    -- illenium-appearance's creator would open twice.
    if isNewCharacter and charRecord.interiorIndex then
        DoScreenFadeOut(Config.FadeTime)
        while not IsScreenFadedOut() do Wait(0) end

        lib.requestModel(model)
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)

        EndOurSelectionState()
        TriggerServerEvent('qbx_properties:server:apartmentSelect', charRecord.interiorIndex)

        UnlockPlayer()
        if NetworkIsInTutorialSession() then
            NetworkEndTutorialSession()
        end

        DoScreenFadeIn(Config.FadeTime)
        FireLoadedEvents()
        return
    end

    DoScreenFadeOut(Config.FadeTime)
    while not IsScreenFadedOut() do Wait(0) end

    lib.requestModel(model)
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    -- New characters carry the chosen apartment's coords in
    -- charRecord.position (set by the createCharacter NUI callback below);
    -- fall back to the generic default spawn only if that's somehow missing.
    local pos = charRecord.position or (isNewCharacter and Config.NewCharacterSpawn or nil)

    if pos and pos.x then
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
        SetEntityHeading(ped, pos.w or 0.0)
    else
        local sp = Config.SpawnPoint
        SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, true)
        SetEntityHeading(ped, sp.w)
    end

    EndOurSelectionState()
    UnlockPlayer()

    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
    end

    DoScreenFadeIn(Config.FadeTime)
    FireLoadedEvents()

    if isNewCharacter then
        -- Opens illenium-appearance's character creator (its qb bridge
        -- listens for this exact event — see
        -- illenium-appearance/client/framework/qb/main.lua). Without this,
        -- brand new characters spawn with the default look and never get a
        -- chance to customize their appearance.
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    end
end

-- ===================================================================
-- Opening the screen
-- ===================================================================

local function OpenSelectUI()
    if inSelect then return end
    inSelect = true

    Debug('OpenSelectUI() started')

    if Config.UseSoloSession then
        Debug('starting solo tutorial session...')
        NetworkStartSoloTutorialSession()
        while not NetworkIsInTutorialSession() do Wait(0) end
        Debug('solo tutorial session active')
    end

    DoScreenFadeOut(Config.FadeTime)
    while not IsScreenFadedOut() do Wait(0) end

    local sp = Config.SpawnPoint
    SetEntityCoords(PlayerPedId(), sp.x, sp.y, sp.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), sp.w)

    LockPlayer()
    CreateSelectCamera()

    currentPreviewModel = nil
    UpdatePreviewPed(nil, 0)

    -- Required for external multicharacter resources, or players get stuck
    -- on the connecting loading screen behind your NUI.
    Debug('calling ShutdownLoadingScreen / ShutdownLoadingScreenNui')
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    SendApartmentList()
    RequestCharacters()

    DoScreenFadeIn(Config.FadeTime)
    Debug('OpenSelectUI() finished — NUI should be visible now')
end

local hasOpenedSelect = false

local function TriggerOpenSelectUI()
    if hasOpenedSelect then return end
    hasOpenedSelect = true
    Debug('TriggerOpenSelectUI() firing OpenSelectUI()')
    OpenSelectUI()
end

-- Same spawn-detection method qbx_core's own built-in multicharacter
-- screen uses (client/character.lua): poll for the network session
-- actually being up, disable spawnmanager's autospawn so it doesn't fight
-- us over the ped, then open immediately — no reliance on the
-- 'playerSpawned' event ever firing.
CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
            Wait(250)
            TriggerOpenSelectUI()
            break
        end
    end
end)

RegisterCommand('crazy_multichar_open', function()
    Debug('/crazy_multichar_open run manually')
    TriggerOpenSelectUI()
end, false)

-- ===================================================================
-- NUI -> qbx_core
-- ===================================================================

RegisterNUICallback('previewCharacter', function(data, cb)
    UpdatePreviewPed(data.citizenid, data.gender)
    cb('ok')
end)

RegisterNUICallback('previewGender', function(data, cb)
    UpdatePreviewPed(nil, data.gender)
    cb('ok')
end)

RegisterNUICallback('createCharacter', function(data, cb)
    -- Exact same payload shape qbx_core's own built-in screen sends to
    -- qbx_core:server:createCharacter — the server computes the real cid
    -- itself and ignores anything we'd send for it.
    local payload = {
        firstname = data.firstName,
        lastname = data.lastName,
        birthdate = data.birthdate,
        nationality = data.nationality,
        gender = tonumber(data.gender) or 0
    }

    local newChar = lib.callback.await('qbx_core:server:createCharacter', false, payload)

    if not newChar then
        SendNUIMessage({ action = 'notify', kind = 'error', message = 'Could not create that identity.' })
        cb('error')
        return
    end

    local apartment = FindApartment(data.apartmentId)
    local position, interiorIndex = nil, nil
    if apartment then
        position = { x = apartment.coords.x, y = apartment.coords.y, z = apartment.coords.z, w = apartment.coords.w }
        interiorIndex = apartment.interiorIndex
    end

    SpawnSelectedCharacter({ charinfo = payload, position = position, interiorIndex = interiorIndex }, true)
    cb('ok')
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    lib.callback.await('qbx_core:server:loadCharacter', false, data.citizenid)
    SpawnSelectedCharacter(data, false)
    cb('ok')
end)

RegisterNUICallback('selectSpawnLocation', function(data, cb)
    local location = FindSpawnLocation(data.id)
    local pos = location and (location.useSavedPosition and pendingExistingCharacter and pendingExistingCharacter.position or location.coords)

    local ped = PlayerPedId()
    if pos and pos.x then
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
        SetEntityHeading(ped, pos.w or 0.0)
    else
        -- Shouldn't happen (every configured location resolves to
        -- something), but don't strand the player faded out if it does.
        local sp = Config.SpawnPoint
        SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, true)
        SetEntityHeading(ped, sp.w)
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    UnlockPlayer()

    if NetworkIsInTutorialSession() then
        NetworkEndTutorialSession()
    end

    DoScreenFadeIn(Config.FadeTime)
    FireLoadedEvents()

    pendingExistingCharacter = nil
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    -- qbx_core:server:deleteCharacter is a plain net event (kept for
    -- backward compatibility), not an ox_lib callback — this is the
    -- documented, stable way to call it from outside qbx_core itself.
    TriggerServerEvent('qbx_core:server:deleteCharacter', data.citizenid)
    Wait(300) -- let qbx_core finish removing it before we refresh the list
    RequestCharacters()
    cb('ok')
end)

RegisterNUICallback('refreshCharacters', function(_, cb)
    RequestCharacters()
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and inSelect then
        UnlockPlayer()
        DestroySelectCamera()
        SetNuiFocus(false, false)
    end
end)
