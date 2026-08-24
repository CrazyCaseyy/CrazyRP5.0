return {
    duration = 60000, -- ms it takes to rob the store
    cashRollsMin = 1, -- minimum cash rolls given on a successful robbery
    cashRollsMax = 3, -- maximum cash rolls given on a successful robbery
    cooldown = 900000, -- ms before the same store can be robbed again (15 min)
    pedModel = `mp_m_shopkeep_01`, -- the GTA Online convenience store clerk model

    -- Melee: the blade has to actually be pointed at the cashier - within this
    -- distance, and with them inside this cone in front of the camera. Just
    -- having a knife out while standing next to them is not a robbery.
    meleeThreatDistance = 3.0,
    meleeAimAngle = 35.0, -- degrees off-centre that still counts as "pointed at"

    -- Also require the aim button to be held for melee. Off by default: the aim
    -- control is unreliable with a blade equipped (the game repurposes it for
    -- block/guard), so requiring it can stop melee triggering at all. The cone
    -- above is what actually enforces "pointed at him".
    meleeRequireAim = false,

    -- Prints the live melee gate values (armed / aiming / distance / cone) to F8
    -- every half second while near a cashier, to see which one is blocking.
    debug = false,

    -- Firearms: aiming a gun anywhere within this radius of the cashier counts,
    -- deliberately without an at-the-ped precision check (see client/main.lua).
    gunThreatDistance = 5.0,

    -- How long the cashier sticks around once a robbery finishes and he's set
    -- loose - fleeing, or shot dead while fleeing, makes no difference, he's
    -- removed either way once this runs out.
    despawnAfterRobbery = 60000,

    -- The progress bar's own cancel key is disabled during a robbery (see
    -- startRobbery) - this distance from the cashier is the only way out once
    -- it's started.
    cancelDistance = 15.0,

    -- One entry per robbable 24/7 / LTD / Rob's Liquor. `coords` is each store's
    -- clerkPos (position + facing heading), and `safe` is that store's
    -- back-room floor safe - both taken as-is from the server's own full
    -- store-robbery config, so they land exactly behind the right counter and
    -- at the right safe prop.
    stores = {
        { coords = vec4(-47.6, -1752.7, 28.43, 135.92), safe = vec3(-42.19, -1752.75, 29.42) },      -- LTD Gasoline - Davis
        { coords = vec4(378.79, 331.85, 102.57, 169.71), safe = vec3(379.44, 324.59, 100.46) },      -- 247 - Clinton
        { coords = vec4(29.52, -1340.25, 28.5, 179.75), safe = vec3(31.58, -1347.6, 26.39) },        -- 247 - Strawberry
        { coords = vec4(2550.52, 385.98, 107.62, 266.44), safe = vec3(2557.82, 387.91, 105.51) },    -- 247 - Palomino Fwy
        { coords = vec4(1703.32, 4924.2, 41.07, 53.61), safe = vec3(1703.61, 4918.68, 42.07) },      -- LTD - Grapeseed
        { coords = vec4(-1825.54, 794.09, 137.18, 225.62), safe = vec3(-1824.61, 799.59, 138.11) },  -- LTD - Banham Canyon
        { coords = vec4(-710.18, -910.05, 18.22, 180.36), safe = vec3(-706.0, -906.64, 19.22) },     -- LTD - Little Seoul
        { coords = vec4(1165.23, 2710.97, 37.16, 188.73), safe = vec3(1169.31, 2717.81, 37.16) },    -- Rob's Liquor - Harmony
        { coords = vec4(1134.05, -983.33, 45.42, 282.59), safe = vec3(1126.78, -980.15, 45.42) },    -- Rob's Liquor - El Rancho
        { coords = vec4(-1221.32, -908.13, 11.33, 37.3), safe = vec3(-1220.79, -916.02, 11.33) },    -- Rob's Liquor - San Andreas
        { coords = vec4(-1487.29, -376.92, 39.16, 153.55), safe = vec3(-1478.95, -375.39, 39.16) },  -- Rob's Liquor - Prosperity St
        { coords = vec4(-2966.3, 391.58, 14.04, 86.15), safe = vec3(-2959.61, 387.16, 14.04) },      -- Rob's Liquor - Great Ocean
        { coords = vec4(2674.33, 3286.89, 54.24, 236.61), safe = vec3(2681.75, 3285.48, 52.13) },    -- 247 - Route 13
        { coords = vec4(1734.94, 6419.33, 34.04, 152.51), safe = vec3(1734.08, 6411.77, 31.93) },    -- 247 - Senora Fwy
        { coords = vec4(1960.57, 3748.25, 31.34, 207.41), safe = vec3(1966.39, 3743.32, 29.23) },    -- 247 - Sandy Shores
        { coords = vec4(545.36, 2663.9, 41.16, 3.27), safe = vec3(541.99, 2670.6, 39.05) },          -- 247 - Route 68
    },

    -- Vault (safe) robbery - a separate, harder target at the same stores.
    -- Independent cooldown/availability from the register, so both can be hit
    -- on their own schedules. No prop is spawned for this - the interaction
    -- sits on the cabinet each store's own map model already has at `safe`.
    vault = {
        duration = 60000, -- ms it takes to crack the safe and grab the cash
        cooldown = 2700000, -- 45 min before the same safe can be cracked again after a success
        failCooldown = 120000, -- 2 min lockout after being interrupted, before trying again
        cancelDistance = 5.0, -- walking this far from the safe cancels the attempt
        rewardMin = 3, -- cash_band given on a successful crack
        rewardMax = 6,

        -- Played for the whole crack via lib.progressBar's own anim handling.
        -- Reused from jim-mechanic's crafting animation (already confirmed
        -- working on this server) rather than an unverified safe-specific one.
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1, blendIn = 1.0 },
    },
}
