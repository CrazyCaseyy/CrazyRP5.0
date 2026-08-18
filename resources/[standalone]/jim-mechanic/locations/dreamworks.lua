Locations = Locations or {}

--[[ FLYWHEELS IN SANDY SHORE ]]--
--[[ xLogicc - https://forum.cfx.re/t/release-flywheels-garage/1436833 ]]

Locations["dreamworks"] = {
	Enabled = true,
	autoClock = { enter = false, exit = false, },
	job = "dreamworks",
	label = "Dreamworks",
	logo = "https://https://static.wikia.nocookie.net/gtawiki/images/c/c6/Flywheels-GTAV-Logo-0.png",
	zones = {
		vec2(1737.60, 3335.52),
        vec2(1772.21, 3355.80),
        vec2(1794.50, 3321.30),
        vec2(1751.00, 3294.07)
	},
	blip = {
        coords = vec3(-723.71, -1519.22, 5.06),
        color = 57,
        sprite = 446,
        disp = 6,
        scale = 0.7,
        cat = nil,
		previewImg = "https://i.imgur.com/rH2aI8o.png",
	},
	Stash = {
		{   coords = vec4(-727.05, -1505.04, 5.09, 299.81),width = 2.25, depth = 2.8,
			label = "Mech Stash: ", icon = "fas fa-cogs",
			slots = 50, maxWeight = 4000000,
		},
	},
    PersonalStash = {
        {   coords = vec4(-729.07, -1503.58, 5.06, 152.87), width = 0.3, depth = 1.3, minZ = 40.44, maxZ = 42.64,
            label = "Personal Stash",
            icon = "fas fa-box-open",
            stashName = "dreamworks_Personal_",
        },
    },
	Shop = {
		{   coords = vec4(-725.12, -1509.13, 4.96, 181.4), width = 1.6, depth = 3.0,
            label = "Shop", icon = "fas fa-box-open",
        },
	},
	Crafting = {
		{	coords = vec4(-722.77, -1518.64, 5.06, 295.04), width = 2.25, depth = 2.8,
			label = "Mechanic Crafting", icon = "fas fa-screwdriver-wrench",
		},
	},
	Clockin = {
		{   prop = { model = "prop_laptop_01a", coords = vec4(-762.74, -1517.95, 5.96, 209.17), },
			label = "Clock on/off", icon = "fas fa-list",
		},
	},
    BossStash = {
		--
    },
	manualRepair = {
		{ 	prop = { model = "xm3_prop_xm3_tool_draw_01d", coords = vec4(-732.98, -1502.83, 5.0, 15.98), },
			label = "Manual Repair", icon = "fas fa-cogs",
		},
	},
	nosRefill = { },
	Payments = {
		{   coords = vec4(-762.74, -1517.95, 5.96, 209.17),
            label = "Charge", icon = "fas fa-credit-card",
        },
	},
    carLift = {
        
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