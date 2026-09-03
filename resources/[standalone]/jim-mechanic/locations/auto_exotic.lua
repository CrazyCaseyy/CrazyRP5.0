Locations = Locations or {}

--[[ AUTO EXOTIC ]]--
--[[ AUTO EXOTIC ]]--

Locations["exotic"] = {
	Enabled = true,
	autoClock = { enter = true, exit = true, },
	job = "exotic",
	label = "Auto Exotic",
	logo = "https://static.wikia.nocookie.net/gtawiki/images/f/f2/GTAV-LSCustoms-Logo.png",
	zones = {
		vec2(521.52, -280.28),
		vec2(542.45, -290.23),
		vec2(568.36, -237.95),
		vec2(577.35, -242.38),
		vec2(594.26, -203.01),
		vec2(586.84, -192.76),
		vec2(562.34, -193.45),
		vec2(561.8, -164.65),
		vec2(556.38, -132.24),
		vec2(530.33, -132.08),
		vec2(524.94, -147.08),
		vec2(530.46, -193.4),
		vec2(538.4, -193.63),
		vec2(537.38, -243.73),
	},
	blip = {
		coords = vec3(549.4, -184.16, 65.07),
		color = 26,
		sprite = 446,
		disp = 6,
		scale = 0.7,
		cat = nil,
		previewImg = "https://i.imgur.com/kKC2Mw2.png",
	},
	Stash = {
		{   coords = vec4(560.12, -181.27, 54.51, 267.89), width = 2.4, depth = 3.6,
			label = "Mech Stash", icon = "fas fa-cogs",
			slots = 50, maxWeight = 4000000,
		},
		{
			coords = vec4(557.88, -187.39, 54.72, 351.38), width = 2.4, depth = 3.5,
			label = "Mech Stash", icon = "fas fa-cogs",
			slots = 50, maxWeight = 4000000,
		},
	},
    PersonalStash = {
        {   coords = vec4(558.66, -198.14, 57.93, 130.59), width = 1.6, depth = 3.5,
            label = "Personal Stash",
            icon = "fas fa-box-open",
            stashName = "AutoExotic_Pstash",
        },
    },
	Shop = {
		{   coords = vec4(557.74, -179.45, 54.26, 92.63), width = 1.6, depth = 3.05,
            label = "Shop", icon = "fas fa-box-open",
        },
		{   coords = vec4(554.19, -187.07, 54.44, 151.8), width = 1.6, depth = 3.05,
            label = "Shop", icon = "fas fa-box-open",
        },
	},
	Crafting = {
		{   coords = vec4(559.3, -171.84, 54.77, 27.77), width = 1.0, depth = 4.05,
			label = "Mechanic Crafting", icon = "fas fa-screwdriver-wrench",
		},
	},
	Clockin = {
		{   prop = { model = "prop_laptop_01a", coords = vec4(554.7, -171.41, 55.3, 182.82), },
            label = "Clock on/off", icon = "fas fa-list",
        },
	},
    BossMenus = {
        {   coords = vec4(560.1, -198.82, 55.54, 272.42), width = 0.4, depth = 0.4,
            label = "Open Bossmenu", icon = "fas fa-list",
        },
    },
    BossStash = {
        {   coords = vec4(560.27, -201.51, 58.09, 202.89), width = 1.6, depth = 2.6,
            label = 'Open Storage', icon = "fa-solid fa-vault",
            stashName = "Exotic_BossStash", stashLabel = "Boss Storage",
            slots = 100, maxWeight = 2000000,
        },
    },
	manualRepair = {
		{ 	prop = { model = "xm3_prop_xm3_tool_draw_01d", coords = vec4(553.12, -203.31, 54.42, 356.28), },
			label = "Manual Repair", icon = "fas fa-cogs",
		},
	},
	nosRefill = {
		{   prop = { model = "prop_byard_gastank02", coords = vec4(121.17, -3044.73, 7.04, 88.96), },
			label = "Refill NOS", icon = "fas fa-list",
		},
	},
	Payments = {
		{   prop = { model = "prop_till_01", coords = vec4(556.77, -171.62, 55.32, 182.27), },
			label = "Charge", icon = "fas fa-credit-card",
		},
	},
	carLiftModels = {
		pylons = "denis3d_carlift_02",
		lift = "denis3d_carlift_01",
		pylonOffset = vec3(-3.0, 0.0, -1.88),
		liftOffset = vec3(-3.0, 0.0, 0.18),
	},
	garage = { -- requires https://github.com/jimathy/jim-jobgarage
		spawn = vec4(163.22, -3009.31, 5.27, 89.72),
		out = vec4(157.37, -3016.57, 7.04, 179.58),
		list = { "towtruck", "panto", "slamtruck", "cheburek", "utillitruck3" },
		prop = true,
	},
    Restrictions = { -- Remove what you DON'T what the location to be able to edit
		Vehicle = { "Compacts", "Sedans", "SUVs", "Coupes", "Muscle", "Sports Classics", "Sports", "Super", "Motorcycles", "Off-road", "Industrial", "Utility", "Vans", "Cycles", "Service", "Emergency", "Commercial", "Boats", },
		Allow = { "tools", "cosmetics", "repairs", "nos", "perform", "chameleon", "paints" },
	},
	discord = {
		link = "",
		color = 2571775,
	},
}