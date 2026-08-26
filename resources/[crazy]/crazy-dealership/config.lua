Config = {}

-- ox_target zone the catalog opens from.
Config.Location = vec3(-1036.72, -1354.36, 4.56)
Config.TargetRadius = 1.5

-- Where a test-drive vehicle is spawned in and the player is warped into it.
Config.TestDriveSpawn = vec4(-1040.85, -1347.07, 4.44, 73.09)

-- How long a test drive lasts before the vehicle despawns (the player is
-- left standing wherever it was, not teleported anywhere).
Config.TestDriveDuration = 120 -- seconds

-- GTA vehicle classes considered "regular cars" for a civilian dealership.
-- Deliberately excludes industrial/military/emergency/service/commercial
-- (work and war vehicles) and non-car types (boats/helicopters/planes/
-- trains/cycles/motorcycles/vans/openwheel) - see qbx_core's own
-- shared/vehicles.lua for the full category list this pulls from.
Config.Categories = {
    { key = 'compacts', label = 'Compacts' },
    { key = 'sedans', label = 'Sedans' },
    { key = 'coupes', label = 'Coupes' },
    { key = 'muscle', label = 'Muscle' },
    { key = 'sportsclassics', label = 'Sports Classics' },
    { key = 'sports', label = 'Sports' },
    { key = 'super', label = 'Super' },
    { key = 'suvs', label = 'SUVs' },
    { key = 'offroad', label = 'Off-Road' },
}

-- Known weaponized vehicles that still fall inside the categories above -
-- GTA's own classification mixes these into otherwise-civilian categories
-- (e.g. the Technical and Menacer are both 'offroad', not 'military').
-- Best-effort list based on which vehicles are actually known to carry a
-- mounted weapon; add to it if anything else turns up.
Config.ExcludedModels = {
    'tampa3',                                  -- Weaponized Tampa (muscle)
    'deluxo',                                  -- Deluxo (sportsclassics)
    'vigilante',                               -- Vigilante (super)
    'toreador',                                -- Toreador (sportsclassics)
    'imperator', 'imperator2', 'imperator3',   -- Apocalypse/Future Shock/Nightmare Imperator (muscle)
    'ratel',                                   -- Ratel (offroad)
    'brutus', 'brutus2', 'brutus3',            -- Apocalypse/Future Shock/Nightmare Brutus (offroad)
    'menacer',                                 -- Menacer (offroad)
    'technical', 'technical2', 'technical3',   -- Technical / Aqua / Custom (offroad)
    'dune3',                                   -- Dune FAV (offroad)
}

-- Its own category in the catalog, empty for now - add entries here once
-- custom vehicles are ready. Same shape as a qbx_core vehicle entry.
---@type { model: string, name: string, brand: string, price: number }[]
Config.CustomVehicles = {}
