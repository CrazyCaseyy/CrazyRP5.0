return {
	General = {
		name = 'Shop',
		blip = {
			id = 59, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'burger', price = 10 },
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
		}, locations = {
			vec3(25.7, -1347.3, 29.49),
			vec3(-3038.71, 585.9, 7.9),
			vec3(-3241.47, 1001.14, 12.83),
			vec3(1728.66, 6414.16, 35.03),
			vec3(1697.99, 4924.4, 42.06),
			vec3(1961.48, 3739.96, 32.34),
			vec3(547.79, 2671.79, 42.15),
			vec3(2679.25, 3280.12, 55.24),
			vec3(2557.94, 382.05, 108.62),
			vec3(373.55, 325.56, 103.56),
		}, targets = {
			{ loc = vec3(25.06, -1347.32, 29.5), length = 0.7, width = 0.5, heading = 0.0, minZ = 29.5, maxZ = 29.9, distance = 1.5 },
			{ loc = vec3(-3039.18, 585.13, 7.91), length = 0.6, width = 0.5, heading = 15.0, minZ = 7.91, maxZ = 8.31, distance = 1.5 },
			{ loc = vec3(-3242.2, 1000.58, 12.83), length = 0.6, width = 0.6, heading = 175.0, minZ = 12.83, maxZ = 13.23, distance = 1.5 },
			{ loc = vec3(1728.39, 6414.95, 35.04), length = 0.6, width = 0.6, heading = 65.0, minZ = 35.04, maxZ = 35.44, distance = 1.5 },
			{ loc = vec3(1698.37, 4923.43, 42.06), length = 0.5, width = 0.5, heading = 235.0, minZ = 42.06, maxZ = 42.46, distance = 1.5 },
			{ loc = vec3(1960.54, 3740.28, 32.34), length = 0.6, width = 0.5, heading = 120.0, minZ = 32.34, maxZ = 32.74, distance = 1.5 },
			{ loc = vec3(548.5, 2671.25, 42.16), length = 0.6, width = 0.5, heading = 10.0, minZ = 42.16, maxZ = 42.56, distance = 1.5 },
			{ loc = vec3(2678.29, 3279.94, 55.24), length = 0.6, width = 0.5, heading = 330.0, minZ = 55.24, maxZ = 55.64, distance = 1.5 },
			{ loc = vec3(2557.19, 381.4, 108.62), length = 0.6, width = 0.5, heading = 0.0, minZ = 108.62, maxZ = 109.02, distance = 1.5 },
			{ loc = vec3(373.13, 326.29, 103.57), length = 0.6, width = 0.5, heading = 345.0, minZ = 103.57, maxZ = 103.97, distance = 1.5 },
		}
	},

	Liquor = {
		name = 'Liquor Store',
		blip = {
			id = 93, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
			{ name = 'burger', price = 15 },
		}, locations = {
			vec3(1135.808, -982.281, 46.415),
			vec3(-1222.915, -906.983, 12.326),
			vec3(-1487.553, -379.107, 40.163),
			vec3(-2968.243, 390.910, 15.043),
			vec3(1166.024, 2708.930, 38.157),
			vec3(1392.562, 3604.684, 34.980),
			vec3(-1393.409, -606.624, 30.319)
		}, targets = {
			{ loc = vec3(1134.9, -982.34, 46.41), length = 0.5, width = 0.5, heading = 96.0, minZ = 46.4, maxZ = 46.8, distance = 1.5 },
			{ loc = vec3(-1222.33, -907.82, 12.43), length = 0.6, width = 0.5, heading = 32.7, minZ = 12.3, maxZ = 12.7, distance = 1.5 },
			{ loc = vec3(-1486.67, -378.46, 40.26), length = 0.6, width = 0.5, heading = 133.77, minZ = 40.1, maxZ = 40.5, distance = 1.5 },
			{ loc = vec3(-2967.0, 390.9, 15.14), length = 0.7, width = 0.5, heading = 85.23, minZ = 15.0, maxZ = 15.4, distance = 1.5 },
			{ loc = vec3(1165.95, 2710.20, 38.26), length = 0.6, width = 0.5, heading = 178.84, minZ = 38.1, maxZ = 38.5, distance = 1.5 },
			{ loc = vec3(1393.0, 3605.95, 35.11), length = 0.6, width = 0.6, heading = 200.0, minZ = 35.0, maxZ = 35.4, distance = 1.5 }
		}
	},

	YouTool = {
		name = 'YouTool',
		blip = {
			id = 402, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'lockpick', price = 10 }
		}, locations = {
			vec3(2748.0, 3473.0, 55.67),
			vec3(342.99, -1298.26, 32.51)
		}, targets = {
			{ loc = vec3(2746.8, 3473.13, 55.67), length = 0.6, width = 3.0, heading = 65.0, minZ = 55.0, maxZ = 56.8, distance = 3.0 }
		}
	},

	Ammunation = {
		name = 'Ammunation',
		blip = {
			id = 110, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'ammo-9', price = 5, },
			{ name = 'WEAPON_KNIFE', price = 200 },
			{ name = 'WEAPON_BAT', price = 100 },
			{ name = 'WEAPON_PISTOL', price = 1000, metadata = { registered = true }, license = 'weapon' }
		}, locations = {
			vec3(-662.42, -934.92, 20.83),   -- Little Seoul
			vec3(815.39, -2155.59, 27.93),   -- East Customs
			vec3(1692.71, 3759.45, 33.71),   -- Sandy
			vec3(-331.49, 6083.19, 30.45),   -- Paleto
			vec3(252.86, -49.22, 68.94),     -- Vinewood
			vec3(16.87, -1106.81, 28.11),    -- PDM
			vec3(2568.89, 293.86, 107.73),   -- Palomino Fwy
			vec3(-1118.72, 2698.17, 17.55),  -- Fort Zancudo
			vec3(843.23, -1033.94, 27.19)    -- Vespucci Boulevard
		}, targets = {
			{ loc = vec3(-662.42, -934.92, 20.83), length = 0.6, width = 0.5, heading = 180.0, minZ = 20.68, maxZ = 21.13, distance = 2.0 }, -- Little Seoul
			{ loc = vec3(815.39, -2155.59, 27.93), length = 0.6, width = 0.5, heading = 360.0, minZ = 27.78, maxZ = 28.23, distance = 2.0 }, -- East Customs
			{ loc = vec3(1692.71, 3759.45, 33.71), length = 0.6, width = 0.5, heading = 227.39, minZ = 33.56, maxZ = 34.01, distance = 2.0 }, -- Sandy
			{ loc = vec3(-331.49, 6083.19, 30.45), length = 0.6, width = 0.5, heading = 225.0, minZ = 30.30, maxZ = 30.75, distance = 2.0 }, -- Paleto
			{ loc = vec3(252.86, -49.22, 68.94), length = 0.6, width = 0.5, heading = 70.0, minZ = 68.79, maxZ = 69.24, distance = 2.0 }, -- Vinewood
			{ loc = vec3(16.87, -1106.81, 28.11), length = 0.6, width = 0.5, heading = 160.0, minZ = 27.96, maxZ = 28.41, distance = 2.0 }, -- PDM
			{ loc = vec3(2568.89, 293.86, 107.73), length = 0.6, width = 0.5, heading = 360.0, minZ = 107.58, maxZ = 108.03, distance = 2.0 }, -- Palomino Fwy
			{ loc = vec3(-1118.72, 2698.17, 17.55), length = 0.6, width = 0.5, heading = 221.82, minZ = 17.40, maxZ = 17.85, distance = 2.0 }, -- Fort Zancudo
			{ loc = vec3(843.23, -1033.94, 27.19), length = 0.6, width = 0.5, heading = 360.0, minZ = 27.04, maxZ = 27.49, distance = 2.0 } -- Vespucci Boulevard
		}
	},

	PoliceArmoury = {
		name = 'Police Armoury',
		groups = shared.police,
		blip = {
			id = 110, colour = 84, scale = 0.8
		}, inventory = {
			{ name = 'ammo-9', price = 5, },
			{ name = 'ammo-rifle', price = 5, },
			{ name = 'WEAPON_FLASHLIGHT', price = 200 },
			{ name = 'WEAPON_NIGHTSTICK', price = 100 },
			{ name = 'WEAPON_PISTOL', price = 500, metadata = { registered = true, serial = 'POL' }, license = 'weapon' },
			{ name = 'WEAPON_CARBINERIFLE', price = 1000, metadata = { registered = true, serial = 'POL' }, license = 'weapon', grade = 3 },
			{ name = 'WEAPON_STUNGUN', price = 500, metadata = { registered = true, serial = 'POL'} }
		}, locations = {
			vec3(451.51, -979.44, 30.68)
		}, targets = {
			{ loc = vec3(453.21, -980.03, 30.68), length = 0.5, width = 3.0, heading = 270.0, minZ = 30.5, maxZ = 32.0, distance = 6 }
		}
	},

	Medicine = {
		name = 'Medicine Cabinet',
		groups = {
			['ambulance'] = 0
		},
		blip = {
			id = 403, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'medikit', price = 26 },
			{ name = 'bandage', price = 5 }
		}, locations = {
			vec3(306.3687, -601.5139, 43.28406)
		}, targets = {

		}
	},

	BlackMarketArms = {
		name = 'Black Market (Arms)',
		inventory = {
			{ name = 'WEAPON_DAGGER', price = 5000, metadata = { registered = false	}, currency = 'black_money' },
			{ name = 'WEAPON_CERAMICPISTOL', price = 50000, metadata = { registered = false }, currency = 'black_money' },
			{ name = 'at_suppressor_light', price = 50000, currency = 'black_money' },
			{ name = 'ammo-rifle', price = 1000, currency = 'black_money' },
			{ name = 'ammo-rifle2', price = 1000, currency = 'black_money' }
		}, locations = {
			vec3(309.09, -913.75, 56.46)
		}, targets = {

		}
	},

	VendingMachineDrinks = {
		name = 'Vending Machine',
		inventory = {
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
		},
		model = {
			`prop_vend_soda_02`, `prop_vend_fridge01`, `prop_vend_water_01`, `prop_vend_soda_01`
		}
	},

	-- Every robbable 24/7 / LTD / Rob's Liquor from crazy-storerobbery, with the
	-- till placed right at the same clerkPos that resource spawns its cashier
	-- at, so the legit shop counter and the robbery target are the same spot.
	Store247 = {
		name = '24/7',
		blip = {
			id = 59, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'water', price = 10 },
			{ name = 'sprunk', price = 10 },
			{ name = 'burger', price = 15 },
			{ name = 'mustard', price = 5 },
			{ name = 'lighter', price = 50 },
			{ name = 'phone', price = 500 },
		}, locations = {
			vec3(-47.6, -1752.7, 28.43),   -- LTD Gasoline - Davis
			vec3(378.79, 331.85, 102.57),  -- 247 - Clinton
			vec3(29.52, -1340.25, 28.5),   -- 247 - Strawberry
			vec3(2550.52, 385.98, 107.62), -- 247 - Palomino Fwy
			vec3(1703.32, 4924.2, 41.07),  -- LTD - Grapeseed
			vec3(-1825.54, 794.09, 137.18), -- LTD - Banham Canyon
			vec3(-710.18, -910.05, 18.22), -- LTD - Little Seoul
			vec3(1165.23, 2710.97, 37.16), -- Rob's Liquor - Harmony
			vec3(1134.05, -983.33, 45.42), -- Rob's Liquor - El Rancho
			vec3(-1221.32, -908.13, 11.33), -- Rob's Liquor - San Andreas
			vec3(-1487.29, -376.92, 39.16), -- Rob's Liquor - Prosperity St
			vec3(-2966.3, 391.58, 14.04),  -- Rob's Liquor - Great Ocean
			vec3(2674.33, 3286.89, 54.24), -- 247 - Route 13
			vec3(1734.94, 6419.33, 34.04), -- 247 - Senora Fwy
			vec3(1960.57, 3748.25, 31.34), -- 247 - Sandy Shores
			vec3(545.36, 2663.9, 41.16),   -- 247 - Route 68
		}, targets = {
			{ loc = vec3(-47.6, -1752.7, 28.43), length = 0.6, width = 0.5, heading = 135.92, minZ = 29.03, maxZ = 29.43, distance = 1.5 },
			{ loc = vec3(378.79, 331.85, 102.57), length = 0.6, width = 0.5, heading = 169.71, minZ = 103.17, maxZ = 103.57, distance = 1.5 },
			{ loc = vec3(29.52, -1340.25, 28.5), length = 0.6, width = 0.5, heading = 179.75, minZ = 29.1, maxZ = 29.5, distance = 1.5 },
			{ loc = vec3(2550.52, 385.98, 107.62), length = 0.6, width = 0.5, heading = 266.44, minZ = 108.22, maxZ = 108.62, distance = 1.5 },
			{ loc = vec3(1703.32, 4924.2, 41.07), length = 0.6, width = 0.5, heading = 53.61, minZ = 41.67, maxZ = 42.07, distance = 1.5 },
			{ loc = vec3(-1825.54, 794.09, 137.18), length = 0.6, width = 0.5, heading = 225.62, minZ = 137.78, maxZ = 138.18, distance = 1.5 },
			{ loc = vec3(-710.18, -910.05, 18.22), length = 0.6, width = 0.5, heading = 180.36, minZ = 18.82, maxZ = 19.22, distance = 1.5 },
			{ loc = vec3(1165.23, 2710.97, 37.16), length = 0.6, width = 0.5, heading = 188.73, minZ = 37.76, maxZ = 38.16, distance = 1.5 },
			{ loc = vec3(1134.05, -983.33, 45.42), length = 0.6, width = 0.5, heading = 282.59, minZ = 46.02, maxZ = 46.42, distance = 1.5 },
			{ loc = vec3(-1221.32, -908.13, 11.33), length = 0.6, width = 0.5, heading = 37.3, minZ = 11.93, maxZ = 12.33, distance = 1.5 },
			{ loc = vec3(-1487.29, -376.92, 39.16), length = 0.6, width = 0.5, heading = 153.55, minZ = 39.76, maxZ = 40.16, distance = 1.5 },
			{ loc = vec3(-2966.3, 391.58, 14.04), length = 0.6, width = 0.5, heading = 86.15, minZ = 14.64, maxZ = 15.04, distance = 1.5 },
			{ loc = vec3(2674.33, 3286.89, 54.24), length = 0.6, width = 0.5, heading = 236.61, minZ = 54.84, maxZ = 55.24, distance = 1.5 },
			{ loc = vec3(1734.94, 6419.33, 34.04), length = 0.6, width = 0.5, heading = 152.51, minZ = 34.64, maxZ = 35.04, distance = 1.5 },
			{ loc = vec3(1960.57, 3748.25, 31.34), length = 0.6, width = 0.5, heading = 207.41, minZ = 31.94, maxZ = 32.34, distance = 1.5 },
			{ loc = vec3(545.36, 2663.9, 41.16), length = 0.6, width = 0.5, heading = 3.27, minZ = 41.76, maxZ = 42.16, distance = 1.5 },
		}
	}
}
