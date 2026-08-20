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

    -- Add more entries here for more robbable stores - starting with just one.
    stores = {
        {
            coords = vec4(25.7, -1347.3, 29.49, 0.0), -- Rob's Liquor, Strawberry - adjust to taste in-game
        },
    },
}
