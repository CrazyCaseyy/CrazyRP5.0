return {
	{
        name = 'debug_crafting',
		items = {
			{
				name = 'lockpick',
				ingredients = {
					scrapmetal = 5,
					WEAPON_HAMMER = 0.05
				},
				duration = 5000,
				count = 2,
			},
		},
		points = {
			vec3(-1147.083008, -2002.662109, 13.180260),
			vec3(-345.374969, -130.687088, 39.009613)
		},
		zones = {
			{
				coords = vec3(-1146.2, -2002.05, 13.2),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 315.0,
			},
			{
				coords = vec3(-346.1, -130.45, 39.0),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 70.0,
			},
		},
		blip = { id = 566, colour = 31, scale = 0.8 },
	},

	-- Burger Shot kitchen - restricted to on-duty burgershot employees.
	-- Coords are the real kitchen spot inside the installed TurboSaif
	-- "Burgershot Vespucci" MLO (tstudio_burgershot), taken in-game.
	{
		name = 'burgershot_kitchen',
		label = 'Burger Shot Kitchen',
		groups = { ['burgershot'] = 0 },
		items = {
			{ name = 'bs_bleeder', ingredients = { bs_bun = 1, bs_patty = 1, bs_lettuce = 1 }, duration = 4000, count = 1 },
			{ name = 'bs_heartstopper', ingredients = { bs_bun = 1, bs_patty = 2 }, duration = 5000, count = 1 },
			{ name = 'bs_meatfree', ingredients = { bs_bun = 1, bs_lettuce = 1, bs_tomato = 1, bs_onion = 1 }, duration = 4000, count = 1 },
			{ name = 'bs_torpedo', ingredients = { bs_bun = 1, bs_patty = 1, bs_onion = 1 }, duration = 4000, count = 1 },
			{ name = 'bs_moneyshot', ingredients = { bs_bun = 1, bs_patty = 2, bs_tomato = 1 }, duration = 5500, count = 1 },
			{ name = 'bs_fries', ingredients = { bs_potato = 1 }, duration = 3000, count = 1 },
			{ name = 'bs_onionrings', ingredients = { bs_onion = 1 }, duration = 3000, count = 1 },
			{ name = 'bs_nuggets', ingredients = { bs_patty = 1 }, duration = 3000, count = 2 },
			{ name = 'bs_sprunk', ingredients = { bs_cup = 1 }, duration = 2000, count = 1 },
			{ name = 'bs_ecola', ingredients = { bs_cup = 1 }, duration = 2000, count = 1 },
			{ name = 'bs_milkshake', ingredients = { bs_cup = 1 }, duration = 3500, count = 1 },
		},
		zones = {
			{
				coords = vec3(-1197.55, -896.08, 12.99),
				size = vec3(2.0, 2.5, 1.5),
				distance = 2.0,
				rotation = 122.87,
			},
		},
	},
}
