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
Config.CameraPoint = vector4(-1038.0, -2726.0, 15.5, 205.0)

-- Slow orbiting showcase camera around the previewed character while the
-- select screen is open. Set enabled = false to use the fixed camera at
-- Config.CameraPoint instead.
Config.PreviewOrbit = {
    enabled = true,
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
-- form. This is a starting-location choice, not a housing/property
-- system — it doesn't grant ownership, rent, or an interior shell, and
-- nothing here persists it beyond the initial spawn. Currently just the
-- one option; add more entries here later if you want a real choice.
-- Coordinates are an approximate street-level spot outside the Alta St
-- apartment towers in Rockford Hills — nudge them with an in-game
-- coords/teleport tool if you want it standing exactly at a doorway.
-- ===================================================================
Config.Apartments = {
    {
        id = 'alta',
        label = 'Alta Apartments',
        blurb = 'Rockford Hills. Quiet, upscale, close to everything.',
        coords = vector4(-782.9, 316.5, 84.7, 340.0)
    }
}
