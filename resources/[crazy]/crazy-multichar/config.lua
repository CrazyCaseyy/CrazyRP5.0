Config = {}

-- Prints checkpoint messages to the F8 console (prefixed [crazy-multichar])
-- so you can see exactly how far client.lua gets. Turn off once things
-- are working.
Config.Debug = true

-- Where the camera looks / where the ped stands while the select screen
-- is open. Purely cosmetic for the selection scene itself — qbx_core (via
-- qbx_spawn, see below) restores each existing character's own saved
-- position after you pick one.
Config.SpawnPoint = vector4(-1035.71, -2731.87, 12.86, 180.0)

-- Positioned directly in front of the ped (still 1.9m along its facing
-- direction for heading 180 — forward = (-sin(180), cos(180)) = (0, -1),
-- unchanged). Camera height (z) is now ABOVE the look-at target (which
-- stays at waist height — see client.lua's PREVIEW_LOOK_HEIGHT) so
-- PointCamAtCoord naturally tilts the shot down at the character from
-- slightly above, instead of a flat level shot.
Config.CameraPoint = vector4(-1035.71, -2733.77, 14.16, 0.0)

-- Slow orbiting showcase camera around the previewed character while the
-- select screen is open. Disabled — the constant spin made it hard to
-- actually look at your character. Camera now just sits fixed at
-- Config.CameraPoint instead.
Config.PreviewOrbit = {
    enabled = false,
    radius = 2.4,  -- meters from the character
    height = 0.9,  -- camera height above the character's feet
    speed = 0.15   -- degrees per frame, roughly — higher is faster
}

-- Fade timings (ms)
Config.FadeTime = 800

-- Start a solo tutorial session while the select screen is open, same as
-- qbx_core's own built-in screen does, so other players can't see/hit you
-- mid-selection. Set to false if that conflicts with another resource.
Config.UseSoloSession = true

-- Default nationality pre-filled in the "new identity" form.
Config.DefaultNationality = 'USA'

-- Fallback spawn for a brand-new character if, for whatever reason, no
-- apartment could be resolved (Config.Apartments empty). Normally unused
-- since every new character picks one of the entries below. This is
-- qbx_core's own config.shared.defaultSpawn value, kept in sync manually
-- since resources can't read each other's Lua config tables directly.
Config.NewCharacterSpawn = vector4(-540.58, -212.02, 37.65, 208.88)

-- ===================================================================
-- Starting apartment picker
-- Shown as step 2 of new-character creation, right after the identity
-- form. Every entry here has an `interiorIndex` — the matching 1-based
-- position in qbx_properties' own Config.apartmentOptions list
-- ([qbx]/qbx_properties/config/shared.lua). Picking one triggers
-- qbx_properties:server:apartmentSelect, which actually INSERTs an
-- owned row into the `properties` table (owner = the new citizenid),
-- creates its stash, and teleports the player inside — a real starter
-- apartment, not just a spawn coordinate. That server event also fires
-- qb-clothes:client:CreateFirstCharacter itself once the property is
-- set up, so SpawnSelectedCharacter must NOT also fire it for these
-- entries (see client/client.lua) or illenium-appearance's creator
-- opens twice.
--
-- `coords` here is only the door/"enter" position (matches
-- qbx_properties' apartmentOptions[interiorIndex].enter) — kept for
-- reference and as the fallback if interiorIndex ever fails to
-- resolve; it is NOT where the player ends up (EnterProperty places
-- them inside the interior shell).
--
-- Currently a single entry (Alta Apartments) — the UI auto-selects it
-- since there's only one (see stepApartment in html/script.js). It
-- reuses the Richard Majestic interior shell but with its own door
-- location, matching the entry appended to qbx_properties'
-- Config.apartmentOptions.
-- ===================================================================
Config.Apartments = {
    {
        id = 'alta',
        label = 'Alta Apartments',
        blurb = 'A quiet apartment complex away from downtown.',
        coords = vector4(-271.06, -957.83, 30.22, 123.47),
        interiorIndex = 7
    }
}

-- ===================================================================
-- Spawn location picker
-- Shown to EXISTING characters after they're selected, replacing
-- qbx_spawn's own scaleform selector entirely (two different pickers
-- back to back was the point of confusion this replaced). Add more
-- entries here later — the UI handles any number of them.
--
-- `useSavedPosition = true` means "wherever this character's row in the
-- players table says they last were" (their apartment/last logout spot),
-- not a fixed coordinate — there's nothing else to configure for it.
--
-- Legion Square coords are the exact values already used elsewhere on
-- this server (qbx_spawn/config/client.lua). MRPD/City Hall/Apartments/
-- Hospital coords were supplied directly.
-- ===================================================================
Config.SpawnLocations = {
    {
        id = 'apartment',
        label = 'Last Location',
        blurb = 'Wake up where you last logged out.',
        useSavedPosition = true
    },
    {
        id = 'legion',
        label = 'Legion Square',
        blurb = 'Downtown Los Santos, in the middle of everything.',
        coords = vector4(195.17, -933.77, 29.7, 144.5)
    },
    {
        id = 'mrpd',
        label = 'MRPD',
        blurb = 'Mission Row Police Station.',
        coords = vector4(435.51, -970.26, 29.72, 178.21)
    },
    {
        id = 'cityhall',
        label = 'City Hall',
        blurb = 'Los Santos City Hall, in the heart of downtown.',
        coords = vector4(-574.45, -633.31, 30.17, 87.17)
    },
    {
        id = 'apartments',
        label = 'Alta Apartments',
        blurb = 'A quiet apartment complex away from downtown.',
        coords = vector4(-271.06, -957.83, 30.22, 123.47)
    },
    {
        id = 'hospital',
        label = 'Hospital',
        blurb = 'Pillbox Hill Medical Center.',
        coords = vector4(-0.41, -410.33, 38.27, 253.36)
    }
}
