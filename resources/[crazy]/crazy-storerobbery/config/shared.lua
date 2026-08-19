return {
    duration = 60000, -- ms it takes to rob the store
    cashRollsMin = 1, -- minimum cash rolls given on a successful robbery
    cashRollsMax = 3, -- maximum cash rolls given on a successful robbery
    cooldown = 900000, -- ms before the same store can be robbed again (15 min)
    threatDistance = 2.5, -- how close a melee weapon has to be to the cashier to count as a threat
    pedModel = `mp_m_shopkeep_01`, -- the GTA Online convenience store clerk model

    -- Add more entries here for more robbable stores - starting with just one.
    stores = {
        {
            coords = vec4(25.7, -1347.3, 29.49, 0.0), -- Rob's Liquor, Strawberry - adjust to taste in-game
        },
    },
}
