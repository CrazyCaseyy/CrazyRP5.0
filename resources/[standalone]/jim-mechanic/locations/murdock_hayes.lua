Locations = Locations or {}

--[[ TUNE UP GARAGE ]]--
--[[ Map4All - https://fivem.map4all-shop.com/package/4967549 ]]

Locations["murdock_hayes"] = {
    Enabled = true,
    autoClock = { enter = false, exit = false, },
    job = "hayes",
    label = "Hayes Mechanic",
    logo = "https://i.imgur.com/74UVnCb.jpeg",
    zones = {
        vec2(523.34, -1345.95),
		vec2(476.31, -1346.77),
		vec2(441.09, -1315.93),
		vec2(452.02, -1302.4),
		vec2(490.52, -1300.4),
		vec2(494.77, -1310.22)
    },
    blip = {
		coords = vec3(489.04, -1327.91, 35.68),
		color = 1,
		sprite = 446,
		disp = 6,
		scale = 0.7,
		cat = nil,
	},
    Stash = {
        {   coords = vec4(486.0, -1324.8, 29.01, 24.4), width = 1.4, depth = 0.8,
            label = "Mech Stash", icon = "fas fa-cogs",
            slots = 50, maxWeight = 4000000,
        },
        {   coords = vec4(502.73, -1346.99, 29.51, 2.4), width = 1.4, depth = 0.8,
            label = "Mech Stash", icon = "fas fa-cogs",
            slots = 50, maxWeight = 4000000,
        },
    },
	Shop = {
        {   coords = vec4(505.46, -1347.53, 28.91, 0.55), width = 0.6, depth = 1.4,
            label = "Shop", icon = "fas fa-box-open",
        },
        {   coords = vec4(480.63, -1326.75, 28.95, 18.73), width = 0.6, depth = 1.4,
            label = "Shop", icon = "fas fa-box-open",
        },
	},
    Crafting = {
        {   coords = vec4(476.05, -1309.91, 28.91, 300.37), width = 2.4, depth = 1.1,
            label = "Mechanic Crafting", icon = "fas fa-screwdriver-wrench",
        },
        -- {   coords = vec4(985.91, -1499.5, 30.5, 1.0), width = 2.4, depth = 1.1,
        --     label = "Mechanic Crafting", icon = "fas fa-screwdriver-wrench",
        -- },
    },
    Clockin = {
        --
    },
    BossMenus = {
        {   coords = vec4(471.51, -1311.12, 29.16, 297.99), width = 0.8, depth = 0.8,
            label = "Open Bossmenu",
            icon = "fas fa-list",
        },
    },
	manualRepair = {
		{ 	prop = { model = "xm3_prop_xm3_tool_draw_01d", coords = vec4(498.43, -1326.05, 29.33, 108.38), },
			label = "Manual Repair", icon = "fas fa-cogs",
		},
	},
    Payments = {
        {   prop = { model = "prop_till_01", coords = vec4(473.27, -1314.4, 30.28, 294.54), },
            label = "Charge",
            icon = "fas fa-credit-card",
        },
    },
    Restrictions = { -- Remove what you DON'T what the location to be able to edit
        Vehicle = { "Compacts", "Sedans", "SUVs", "Coupes", "Muscle", "Sports Classics", "Sports", "Super", "Motorcycles", "Off-road", "Industrial", "Utility", "Vans", "Cycles", "Service", "Emergency", "Commercial", "Boats", },
        Allow = { "tools", "cosmetics", "repairs", "nos", "perform", "chameleon", "paints" },
    },
    nosRefill = {
		{   prop = { model = "prop_byard_gastank02", coords = vec4(996.0, -1492.33, 31.5, 181.0), },
			label = "Refill NOS", icon = "fas fa-list",
		},
	},
    discord = {
        link = "",
        color = 16711680,
    }
}