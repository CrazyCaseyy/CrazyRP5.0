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

-- Positioned directly in front of the ped (2m along its facing direction
-- for heading 180 — forward = (-sin(180), cos(180)) = (0, -1)) at roughly
-- chest/eye height, so the camera looks straight at the character's face
-- close-up instead of down at them from an angle. See client.lua's
-- CreateSelectCamera — it aims this at Config.SpawnPoint's chest height,
-- not literal ground level, to match.
Config.CameraPoint = vector4(-1035.71, -2733.87, 14.41, 0.0)

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
-- form. Unlike a plain spawn-point picker, every entry here has an
-- `interiorIndex` — the matching 1-based position in qbx_properties'
-- own Config.apartmentOptions list
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
-- ===================================================================
Config.Apartments = {
    {
        id = 'delperro4',
        label = 'Del Perro Heights Apt 4',
        blurb = 'Ocean views far away from tourists and bums on Del Perro Beach.',
        coords = vector4(-1447.35, -537.84, 34.74, 235.0),
        interiorIndex = 1
    },
    {
        id = 'delperro7',
        label = 'Del Perro Heights Apt 7',
        blurb = 'Luxury complex overlooking the beach.',
        coords = vector4(-1447.35, -537.84, 34.74, 235.0),
        interiorIndex = 2
    },
    {
        id = 'integrity28',
        label = '4 Integrity Way Apt 28',
        blurb = 'An up-and-coming Downtown neighborhood.',
        coords = vector4(-59.4, -616.29, 37.36, 250.0),
        interiorIndex = 3
    },
    {
        id = 'integrity30',
        label = '4 Integrity Way Apt 30',
        blurb = 'An expansive high-rise unit Downtown.',
        coords = vector4(-47.52, -585.86, 37.95, 250.0),
        interiorIndex = 4
    },
    {
        id = 'majestic',
        label = 'Richard Majestic Apt',
        blurb = 'A breathtaking luxury condo near AKAN Records.',
        coords = vector4(-936.15, -378.91, 38.96, 115.0),
        interiorIndex = 5
    },
    {
        id = 'tinsel',
        label = 'Tinsel Towers Apt',
        blurb = 'High-rise living in Downtown Vinewood.',
        coords = vector4(-614.58, 46.52, 43.59, 91.0),
        interiorIndex = 6
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
-- Legion Square and MRPD coords are the exact values already used
-- elsewhere on this server (qbx_spawn/config/client.lua and
-- qbx_police/config/shared.lua's Mission Row station), not new guesses.
-- ===================================================================
Config.SpawnLocations = {
    {
        id = 'apartment',
        label = 'Your Apartment',
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
        coords = vector4(434.0, -983.0, 30.7, 90.0)
    }
}
