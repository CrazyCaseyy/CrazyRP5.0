Locations = Locations or {}

--[[ PDM VESPUCCI MECHANIC ]]--
--[[ AS MLO - https://as-mlo.tebex.io/package/6038374 ]]--

Locations["pdm_vespucci_asmlo"] = {
	Enabled = true,
	autoClock = { enter = false, exit = false, },
	job = "standcustoms",
	label = "Stand Customs",
	zones = {
		vec2(736.61, 1283.64),
		vec2(803.14, 1269.59),
		vec2(804.03, 1282.11),
		vec2(787.1, 1301.53),
		vec2(776.38, 1317.75),
		vec2(738.92, 1319.01),
		vec2(653.41, 1290.02),
		vec2(655.46, 1272.67),
		vec2(716.02, 1269.92),
		vec2(746.64, 1253.8)
	},
	Stash = {
		{ coords = vec4(742.33, 1281.83, 360.7, 162.95), width = 5.2, depth = 0.6,
			label = "Mech Stash", icon = "fas fa-cogs",
			slots = 50, maxWeight = 4000000,
		},
	},
	Shop = {
        {   coords = vec4(750.52, 1281.89, 360.46, 190.98), width = 1.8, depth = 3.5, minZ = 360.32, maxZ = 360.60,
            label = "Shop", icon = "fas fa-box-open",
        },
	},
	Crafting = {
		--
	},
    PersonalStash = {
        {   coords = vec4(756.33, 1302.29, 357.05, 95.39), width = 1.5, depth = 0.8,
            label = "Personal Stash",
            icon = "fas fa-box-open",
            stashName = "pdmVesp_Personal_",
        },
    },
    BossMenus = {
        {   coords = vec4(772.99, 1284.87, 360.15, 137.02), width = 0.8, depth = 0.8,
            label = "Open Bossmenu",
            icon = "fas fa-list",
        },
    },
	Clockin = { },
    Payments = {
        {   prop = { model = "prop_till_01", coords = vec4(754.22, 1286.00, 361.42, 90.00), },
            label = "Charge",
            icon = "fas fa-credit-card",
        },
    },
	manualRepair = {
		{ 	prop = { model = "xm3_prop_xm3_tool_draw_01d", coords = vec4(777.3, 1288.0, 360.3, 270.00), },
			label = "Manual Repair", icon = "fas fa-cogs",
		},
	},
    Restrictions = { -- Remove what you DON'T what the location to be able to edit
		Vehicle = { "Compacts", "Sedans", "SUVs", "Coupes", "Muscle", "Sports Classics", "Sports", "Super", "Motorcycles", "Off-road", "Industrial", "Utility", "Vans", "Cycles", "Service", "Emergency", "Commercial", "Boats", },
		Allow = { "tools", "cosmetics", "repairs", "nos", "perform", "chameleon", "paints" },
	},
	discord = {
		link = "",
		color = 2571775,
	}
}