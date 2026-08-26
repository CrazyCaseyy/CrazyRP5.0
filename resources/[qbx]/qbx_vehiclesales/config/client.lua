return {
    -- ox_target zones the catalog opens from - one at the main counter
    -- plus a few more scattered around the lot so players can browse from
    -- next to the actual showroom cars, not just the one spot.
    browsePoints = {
        vec3(-1036.72, -1354.36, 4.56),
        vec3(-1021.34, -1373.77, 4.55),
        -- vec3(-1027.32, -1378.27, 4.55) removed - closest to (-1026.86, -1378.39, 4.55)
        vec3(-1045.36, -1362.16, 4.55),
        vec3(-1043.3, -1374.02, 4.55),
        vec3(-1021.0, -1359.94, 5.02),
    },
    targetRadius = 1.5,

    -- Showroom display vehicles - purely visual, frozen, never driveable.
    -- Each one is paired with whichever browsePoint above is physically
    -- closest to it (computed at runtime, see client/main.lua), so
    -- picking "Set as Preview" from that particular browse point's menu
    -- always changes the display car actually standing next to the
    -- player, not some other one across the lot.
    previewPoints = {
        vec4(-1032.32, -1358.1, 4.55, 170.98),
        vec4(-1020.9, -1369.05, 4.55, 70.44),
        vec4(-1047.49, -1370.07, 4.55, 253.72),
        vec4(-1045.94, -1365.34, 4.55, 250.13),
        vec4(-1026.8, -1359.67, 4.55, 162.85),
    },

    -- Where a test-drive vehicle is spawned in and the player is warped
    -- into it.
    testDriveSpawn = vec4(-1040.85, -1347.07, 4.44, 73.09),

    -- How long a test drive lasts before the vehicle despawns (the player
    -- is left standing wherever it was, not teleported anywhere).
    testDriveDuration = 120, -- seconds

    -- GTA vehicle classes considered "regular cars" for a civilian
    -- dealership. Deliberately excludes industrial/military/emergency/
    -- service/commercial (work and war vehicles) and non-car types
    -- (boats/helicopters/planes/trains/cycles/motorcycles/vans/openwheel)
    -- - see qbx_core's own shared/vehicles.lua for the full category list
    -- this pulls from.
    categories = {
        { key = 'compacts', label = 'Compacts' },
        { key = 'sedans', label = 'Sedans' },
        { key = 'coupes', label = 'Coupes' },
        { key = 'muscle', label = 'Muscle' },
        { key = 'sportsclassics', label = 'Sports Classics' },
        { key = 'sports', label = 'Sports' },
        { key = 'super', label = 'Super' },
        { key = 'suvs', label = 'SUVs' },
        { key = 'offroad', label = 'Off-Road' },
    },

    -- Known weaponized vehicles that still fall inside the categories
    -- above - GTA's own classification mixes these into otherwise-
    -- civilian categories (e.g. the Technical and Menacer are both
    -- 'offroad', not 'military'). Best-effort list based on which
    -- vehicles are actually known to carry a mounted weapon; add to it
    -- if anything else turns up.
    excludedModels = {
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

        -- Every Apocalypse/Future Shock/Nightmare liveried vehicle left in
        -- the allowed categories (the ones above were already out for
        -- being weaponized too - this is everything else with that
        -- theme). Full list pulled directly from qbx_core's own
        -- shared/vehicles.lua, not guessed.
        'bruiser', 'bruiser2', 'bruiser3',         -- Apocalypse/Future Shock/Nightmare Bruiser (offroad)
        'dominator5', 'dominator6',                -- Future Shock/Nightmare Dominator (muscle - no Apocalypse variant exists)
        'impaler2', 'impaler3', 'impaler4',        -- Apocalypse/Future Shock/Nightmare Impaler (muscle)
        'issi4', 'issi5', 'issi6',                 -- Apocalypse/Future Shock/Nightmare Issi (compacts)
        'monster3', 'monster4', 'monster5',        -- Apocalypse/Future Shock/Nightmare Sasquatch (offroad)
        'slamvan4', 'slamvan5', 'slamvan6',        -- Apocalypse/Future Shock/Nightmare Slamvan (muscle)
        'zr380', 'zr3802', 'zr3803',               -- Apocalypse/Future Shock/Nightmare ZR380 (sports)
    },

    -- Its own category in the catalog, empty for now - add entries here
    -- once custom vehicles are ready. Same shape as a qbx_core vehicle
    -- entry: { model, name, brand, price }.
    customVehicles = {},
}
