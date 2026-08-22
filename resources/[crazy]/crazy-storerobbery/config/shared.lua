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

    -- One entry per robbable 24/7 / LTD / Rob's Liquor. Coords are each store's
    -- clerkPos (position + facing heading) - taken as-is from the server's own
    -- full store-robbery config, so these land exactly behind the right counter.
    stores = {
        { coords = vec4(-47.6, -1752.7, 28.43, 135.92) },      -- LTD Gasoline - Davis
        { coords = vec4(378.79, 331.85, 102.57, 169.71) },     -- 247 - Clinton
        { coords = vec4(29.52, -1340.25, 28.5, 179.75) },      -- 247 - Strawberry
        { coords = vec4(2550.52, 385.98, 107.62, 266.44) },    -- 247 - Palomino Fwy
        { coords = vec4(1703.32, 4924.2, 41.07, 53.61) },      -- LTD - Grapeseed
        { coords = vec4(-1825.54, 794.09, 137.18, 225.62) },   -- LTD - Banham Canyon
        { coords = vec4(-710.18, -910.05, 18.22, 180.36) },    -- LTD - Little Seoul
        { coords = vec4(1165.23, 2710.97, 37.16, 188.73) },    -- Rob's Liquor - Harmony
        { coords = vec4(1134.05, -983.33, 45.42, 282.59) },    -- Rob's Liquor - El Rancho
        { coords = vec4(-1221.32, -908.13, 11.33, 37.3) },     -- Rob's Liquor - San Andreas
        { coords = vec4(-1487.29, -376.92, 39.16, 153.55) },   -- Rob's Liquor - Prosperity St
        { coords = vec4(-2966.3, 391.58, 14.04, 86.15) },      -- Rob's Liquor - Great Ocean
        { coords = vec4(2674.33, 3286.89, 54.24, 236.61) },    -- 247 - Route 13
        { coords = vec4(1734.94, 6419.33, 34.04, 152.51) },    -- 247 - Senora Fwy
        { coords = vec4(1960.57, 3748.25, 31.34, 207.41) },    -- 247 - Sandy Shores
        { coords = vec4(545.36, 2663.9, 41.16, 3.27) },        -- 247 - Route 68
    },
}
