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

-- How far above the ped's feet (Config.SpawnPoint.z) the camera aims —
-- shin height (0.6) cropped their head off; raised to waist height. At
-- the current 1.9m distance / 57° FOV, this centers the frame so the
-- whole character (head to shoes) fits without needing to zoom out.
local PREVIEW_LOOK_HEIGHT = 0.9

-- Slightly wider than DEFAULT_SCRIPTED_CAMERA's own default FOV (~50) so
-- the frame has enough vertical room for the whole character, head to
-- shoes, without needing to back the camera further away.
local PREVIEW_FOV = 57.0

local function CreateSelectCamera()
    local c = Config.CameraPoint
    local sp = Config.SpawnPoint
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, c.x, c.y, c.z)
    PointCamAtCoord(cam, sp.x, sp.y, sp.z + PREVIEW_LOOK_HEIGHT)
    SetCamFov(cam, PREVIEW_FOV)
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
-- Spawn-location preview
-- A scripted camera hovers directly over whichever spawn location is
-- currently picked, so the player can actually see where they're about
-- to end up instead of choosing blind. The player is moved into their
-- own solo routing bucket for this (see server/server.lua) so the real
-- map geometry is visible but no other real players/peds/vehicles are -
-- a floating camera near real spawn points would otherwise double as a
-- way to scout other players before ever loading in.
-- ===================================================================

-- Set while an existing character is between "selected" and "actually
-- placed in the world" — waiting on the player to pick a spawn location in
-- the modal_spawn NUI. Holds the character record so the 'apartment'
-- (useSavedPosition) option has somewhere to read the saved position from.
local pendingExistingCharacter = nil

local function ResolveSpawnLocationPos(locationId)
    local location = FindSpawnLocation(locationId)
    if not location then return nil end
    if location.useSavedPosition then
        return pendingExistingCharacter and pendingExistingCharacter.position or nil
    end
    return location.coords
end

local spawnPreviewCam = nil

-- Height above the location and downward pitch for the hovering preview
-- shot - high up and pitched almost straight down for a true top-down
-- "hovering over the city" view (not quite -90 to sidestep any pitch
-- gimbal weirdness exactly at straight down).
local SPAWN_PREVIEW_HEIGHT = 220.0
local SPAWN_PREVIEW_PITCH = -89.0

-- How long a switch between two spawn-location previews takes to glide
-- from one to the other, instead of just cutting.
local SPAWN_PREVIEW_TRANSITION_MS = 900

-- A scripted camera hovering 220m up is far outside the game's normal
-- "load detail around the player" radius, so without help the world under
-- it renders in low-LOD/pop-in for a moment. SetFocusArea tells the
-- streaming system to also prioritize high-detail loading around THIS
-- point (the same mechanism cutscene/spectator cameras rely on), and
-- RequestCollisionAtCoord gets the ground/roads themselves streamed in
-- too - both cleared via ClearFocus/RemoveCollisionRequests once the
-- preview ends so streaming goes back to centering on the player.
local function FocusStreamingAt(pos)
    if not pos then return end
    SetFocusArea(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
end

local function MakeSpawnPreviewCam(pos)
    local newCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(newCam, pos.x, pos.y, pos.z + SPAWN_PREVIEW_HEIGHT)
    SetCamRot(newCam, SPAWN_PREVIEW_PITCH, 0.0, pos.w or 0.0, 2)
    return newCam
end

-- First call (no camera up yet) just activates the cam directly and fades
-- the screen onto it. Every call after that swaps to a freshly-positioned
-- second camera with SetCamActiveWithInterp, so switching between
-- locations glides smoothly instead of teleporting - the old camera is
-- destroyed once the blend finishes.
local function SetSpawnPreviewCamPos(pos)
    if not pos then return end

    FocusStreamingAt(pos)
    local newCam = MakeSpawnPreviewCam(pos)

    if spawnPreviewCam then
        local oldCam = spawnPreviewCam
        SetCamActiveWithInterp(newCam, oldCam, SPAWN_PREVIEW_TRANSITION_MS, 1, 1)
        spawnPreviewCam = newCam

        CreateThread(function()
            Wait(SPAWN_PREVIEW_TRANSITION_MS + 100)
            DestroyCam(oldCam, false)
        end)
    else
        SetCamActive(newCam, true)
        spawnPreviewCam = newCam

        -- Give the streaming system a moment's head start on the focus
        -- area above before the fade-in actually reveals it.
        Wait(300)

        RenderScriptCams(true, true, Config.FadeTime, true, true)
    end
end

local function CreateSpawnPreviewCamera(pos)
    SetSpawnPreviewCamPos(pos)
end

local function DestroySpawnPreviewCamera()
    if spawnPreviewCam then
        RenderScriptCams(false, true, Config.FadeTime, true, true)
        DestroyCam(spawnPreviewCam, false)
        spawnPreviewCam = nil
        ClearFocus()
    end
end

-- Player's own server id doubles as a guaranteed-unique bucket number;
-- bucket 0 is the shared world everyone else is in.
local function EnterSoloBucket()
    pcall(function() lib.callback.await('crazy-multichar:server:enterSoloBucket', false) end)
end

local function LeaveSoloBucket()
    pcall(function() lib.callback.await('crazy-multichar:server:leaveSoloBucket', false) end)
end

-- ===================================================================
-- Live preview ped
-- Shows the player's own (frozen, invulnerable) ped in front of the
-- camera during selection, updating it whenever a different slot is
-- focused. For an existing character this renders their REAL saved look
-- (clothes, face, hair, tattoos — everything illenium-appearance stores),
-- not just their base gender model — fetched via
-- 'crazy-multichar:server:getAppearance' (server/server.lua) and applied
-- with illenium-appearance's own exported setPlayerAppearance, the same
-- function it uses internally to restore your look on login. New/empty
-- slots fall back to a plain default-gender model since there's no saved
-- appearance yet to show.
-- ===================================================================

local currentPreviewKey = nil

local function UpdatePreviewPed(citizenId, gender)
    gender = tonumber(gender) or 0
    local fallbackModel = (gender == 1) and `mp_f_freemode_01` or `mp_m_freemode_01`

    local appearance = nil
    if citizenId then
        local ok, result = pcall(function()
            return lib.callback.await('crazy-multichar:server:getAppearance', false, citizenId)
        end)
        if ok then appearance = result end
    end

    local previewKey = appearance and ('char:' .. citizenId) or ('gender:' .. gender)
    if currentPreviewKey == previewKey then return end
    currentPreviewKey = previewKey

    if appearance and appearance.model then
        exports['illenium-appearance']:setPlayerAppearance(appearance)
    else
        lib.requestModel(fallbackModel)
        SetPlayerModel(PlayerId(), fallbackModel)
        SetModelAsNoLongerNeeded(fallbackModel)
    end

    local ped = PlayerPedId()
    local sp = Config.SpawnPoint
    SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, true)
    SetEntityHeading(ped, sp.w)
    SetEntityVisible(ped, true, false)

    -- Same scenario scully_emotemenu's own /e flex command plays
    -- (shared/data/scenarios.lua) - a bit of personality while looking at
    -- your character instead of just standing there. Scenarios loop on
    -- their own once started, so this only needs (re)triggering here,
    -- right after the ped potentially got swapped out by a model/
    -- appearance change above.
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_MUSCLE_FLEX', 0, true)
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
    -- Bring crazy-hud back now that the player has actually spawned in —
    -- see the matching hide call in OpenSelectUI(). This is the one choke
    -- point every finalized spawn path (new character w/ apartment, new
    -- character plain, existing character via selectSpawnLocation) runs
    -- through, so it only needs wiring here, not at each call site.
    TriggerEvent('core-hud:client:hidehud', true)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end

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

        -- Ped isn't part of this scene at all (the camera hovers over the
        -- city, not the character) - hide it so it can't end up visible in
        -- some odd frame, and keep it out of the shared world while a
        -- floating camera is up.
        local ped = PlayerPedId()
        SetEntityVisible(ped, false, false)
        pendingExistingCharacter = charRecord
        EnterSoloBucket()

        local firstLocation = Config.SpawnLocations[1]
        local firstPos = (firstLocation and ResolveSpawnLocationPos(firstLocation.id)) or Config.SpawnPoint
        CreateSpawnPreviewCamera(firstPos)

        -- Unlike the rest of this function, we fade back IN here - the
        -- whole point is to actually show the player the hovering preview
        -- while they pick, not stay on a black screen until they confirm.
        DoScreenFadeIn(Config.FadeTime)

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

    -- crazy-hud can already be showing here — e.g. reopening this screen
    -- via /crazy_multichar_open while already loaded in, or a leftover
    -- state from a previous session. Hidden now, restored in
    -- FireLoadedEvents() once the player actually spawns back in.
    TriggerEvent('core-hud:client:hidehud', false)

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

-- qbx_core's own /logout command (server/commands.lua, admin-restricted)
-- calls Logout(source), which unregisters the player and fires this event
-- unconditionally. qbx_core's own client-side handler for it lives in
-- client/character.lua, but that entire file no-ops when
-- useExternalCharacters is true (see its line 4) - so with crazy-multichar
-- installed nothing was ever listening for this, and /logout just tore
-- down the player's data server-side while the client sat there with no
-- HUD and the same character ped still standing in the world. This is the
-- external-screen equivalent: send them back to full character select,
-- the same flow OpenSelectUI() already runs on a fresh connect.
RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end -- only ever valid triggered from the server
    Debug('qbx_core:client:playerLoggedOut received - reopening character select')
    OpenSelectUI()
end)

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

-- Fired on every card click in the spawn-location list (not just the
-- final confirm) - moves the hovering preview camera to that location so
-- the player can see it before committing.
RegisterNUICallback('previewSpawnLocation', function(data, cb)
    local pos = ResolveSpawnLocationPos(data.id) or Config.SpawnPoint
    SetSpawnPreviewCamPos(pos)
    cb('ok')
end)

RegisterNUICallback('selectSpawnLocation', function(data, cb)
    local pos = ResolveSpawnLocationPos(data.id) or Config.SpawnPoint

    DoScreenFadeOut(Config.FadeTime)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
    SetEntityHeading(ped, pos.w or 0.0)

    DestroySpawnPreviewCamera()
    LeaveSoloBucket()

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
    if resource ~= GetCurrentResourceName() then return end

    -- inSelect is already false by the time the spawn-location preview is
    -- up (EndOurSelectionState() clears it before that phase even starts),
    -- so this cleanup can't be gated on it - always safe to call, both are
    -- no-ops if neither was actually active.
    DestroySpawnPreviewCamera()
    LeaveSoloBucket()

    if inSelect then
        UnlockPlayer()
        DestroySelectCamera()
        SetNuiFocus(false, false)
    end
end)
