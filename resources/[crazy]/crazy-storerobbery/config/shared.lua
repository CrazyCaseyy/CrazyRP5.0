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

    -- One entry per robbable 24/7 / Rob's Liquor. Coords are the cashier spot
    -- inside each store, taken from the register positions already mapped out
    -- in qbx_storerobbery's config - adjust headings/positions to taste in-game.
    stores = {
        { coords = vec4(25.7, -1347.3, 29.49, 0.0) },      -- Strawberry
        { coords = vec4(-706.12, -914.46, 19.21, 0.0) },   -- Davis
        { coords = vec4(-47.91, -1758.43, 29.56, 0.0) },
        { coords = vec4(1164.88, -323.54, 69.2, 0.0) },
        { coords = vec4(372.86, 327.52, 103.56, 0.0) },
        { coords = vec4(-1819.54, 793.59, 138.08, 0.0) },
        { coords = vec4(2556.05, 381.22, 108.62, 0.0) },
        { coords = vec4(2677.05, 3279.96, 55.24, 0.0) },
        { coords = vec4(1959.55, 3740.99, 32.34, 0.0) },
        { coords = vec4(549.24, 2670.23, 42.15, 0.0) },
        { coords = vec4(1728.36, 6416.2, 35.03, 0.0) },
        { coords = vec4(1697.48, 4923.85, 42.06, 0.0) },
        { coords = vec4(-3243.4, 1000.06, 12.83, 0.0) },
        { coords = vec4(-3040.03, 584.19, 7.9, 0.0) },
        { coords = vec4(-1222.03, -908.32, 12.32, 0.0) },
        { coords = vec4(-1486.26, -378.0, 40.16, 0.0) },
        { coords = vec4(1134.15, -982.53, 46.41, 0.0) },
        { coords = vec4(1165.9, 2710.81, 38.15, 0.0) },
        { coords = vec4(-2966.46, 390.89, 15.04, 0.0) },
    },
}
