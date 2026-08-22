return {
    job = 'burgershot', -- must match a job in qbx_core's shared/jobs.lua (type = 'business')

    -- Real coords from the installed TurboSaif "Burgershot Vespucci" MLO
    -- (tstudio_burgershot), taken in-game with /bslocation. Duty reuses the
    -- register counter, and management reuses the storage room - the MLO
    -- doesn't have dedicated spots for either.
    locations = {
        duty = vec4(-1192.87, -894.79, 12.99, 316.7), -- Register
        register = vec4(-1192.87, -894.79, 12.99, 316.7), -- Register
        stock = vec4(-1201.3, -888.78, 12.99, 127.84), -- Refrigerator
        management = vec4(-1200.99, -898.2, 12.99, 133.98), -- Storage
    },

    -- Percentage of each sale (0-1) paid directly to the seller as a cash tip,
    -- on top of their normal job paycheck. The rest goes to the business
    -- account (Renewed-Banking job account for `job`, viewable/withdrawable
    -- via the boss menu at the management point).
    tipPercent = 0.15,

    -- Finished items sellable at the register. `price` is what the business
    -- earns per unit sold.
    menu = {
        { name = 'bs_bleeder', label = 'The Bleeder', price = 18 },
        { name = 'bs_heartstopper', label = 'Heart Stopper', price = 24 },
        { name = 'bs_meatfree', label = 'Meat Free', price = 16 },
        { name = 'bs_torpedo', label = 'Torpedo', price = 20 },
        { name = 'bs_moneyshot', label = 'Money Shot', price = 28 },
        { name = 'bs_fries', label = 'Shot Fries', price = 8 },
        { name = 'bs_onionrings', label = 'Shot Rings', price = 9 },
        { name = 'bs_nuggets', label = 'Shot Nuggets', price = 10 },
        { name = 'bs_sprunk', label = 'Sprunk', price = 6 },
        { name = 'bs_ecola', label = 'eCola', price = 6 },
        { name = 'bs_milkshake', label = 'Milkshake', price = 12 },
    },

    -- Raw ingredients purchasable at the stock point. `cost` is paid out of
    -- the business account (not the employee's own cash) per `amount` given.
    stock = {
        { name = 'bs_bun', label = 'Burger Buns', cost = 25, amount = 5 },
        { name = 'bs_patty', label = 'Patties', cost = 40, amount = 5 },
        { name = 'bs_lettuce', label = 'Lettuce', cost = 15, amount = 5 },
        { name = 'bs_tomato', label = 'Tomatoes', cost = 15, amount = 5 },
        { name = 'bs_onion', label = 'Onions', cost = 15, amount = 5 },
        { name = 'bs_potato', label = 'Potatoes', cost = 20, amount = 5 },
        { name = 'bs_cup', label = 'Cups', cost = 10, amount = 5 },
    },
}
