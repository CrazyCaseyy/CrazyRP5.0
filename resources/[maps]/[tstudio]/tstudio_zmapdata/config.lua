-- ## Interior Configurations
Config = {
    Debug = false, -- Set to true to enable debug prints
    ElevatorsEnabled = false, -- Set to false to disable all elevator logic (no markers, no blips, no menus)
    Locale = "en", -- Default locale for elevator menus and prompts (e.g., "en", "de")

    -- ProximityMenu UI defaults
    -- position: "left", "right", "center"
    -- size: "small", "medium", "large"
    MenuUI = {
        elevators    = { position = "left", size = "medium" },
        carElevators = { position = "left", size = "medium" },
        smartSwitches = { position = "left", size = "medium" },
    },

    -- Scenarios config is loaded from scenarios/*.lua files
    -- (npc_removal.lua, navmesh.lua, areas.lua)
    Scenarios = {},
    
    -- Custom Help Notify Function (optional)
    -- If set to nil, the default help notify will be used
    -- Example custom function:
    -- CustomHelpNotify = function(text)
    --     exports['your_notification']:ShowHelp(text)
    -- end
    CustomHelpNotify = nil, -- Set to your custom help notify function or nil for default

    -- EntitySets are now loaded dynamically from the entitysets/ folder
    -- Each location has its own file (laundromats.lua, peak_towers_apartments.lua, etc.)
    -- The entity sets are loaded by client/entitysets_file_loader.lua
    EntitySets = {},


    -- Privacy Glass Switches
    -- Each entry is a switch group for a specific interior.
    -- Each switch in the group toggles independently and syncs across all players in the interior.
    -- State is in-memory only (resets on resource restart).
    --
    -- Required fields:
    --   name: Debug/identification label
    --   coords: Interior coordinates for GetInteriorAtCoords
    --   switches: Array of switch positions, each with:
    --     pos: vector3 marker position
    --     entitySetOn: Entity set name to activate when toggled ON
    --     entitySetOff: Entity set name to activate when toggled OFF
    --
    -- Optional fields:
    --   marker: {type, r, g, b, alpha} — defaults to {type=6, r=19, g=87, b=66, alpha=100}
    --   range: Interaction range — defaults to 2.0
    PrivacySwitches = {
        {
            name = "Pillbox MD Privacy Glass",
            coords = vector3(306.003, -568.511, 63.181),
            switches = {
                { pos = vector3(306.003, -568.511, 63.181), entitySetOn = "r7_privacy_on", entitySetOff = "r7_privacy_off" }, -- Office 1
                { pos = vector3(305.963, -568.432, 67.184), entitySetOn = "r7_privacy_on", entitySetOff = "r7_privacy_off" }, -- Office 2
                { pos = vector3(306.056, -568.902, 59.229), entitySetOn = "r7_privacy_on", entitySetOff = "r7_privacy_off" }, -- Office 3
            },
            marker = {type = 6, r = 19, g = 87, b = 66, alpha = 100},
            range = 2.0,
        },
    },

    -- CompatibilityPatches are now loaded dynamically from the patches/ folder
    -- Each creator has their own file (tstudio.lua, fiv3devs.lua, kiiya.lua, etc.)
    -- This makes it easier to manage and organize patches by creator
    -- The patches are loaded by client/patch_loader.lua
    CompatibilityPatches = {
        -- Patches are now loaded from patches/*.lua files
        -- To add new patches, edit the appropriate creator file in patches/ folder
    },

    -- Section for automatic floor ipl loading configurations
    FloorConfigs = {
        pillbox = {
            resourceName = "tstudio_pillbox_md", -- Added name for debug purposes
            center = vector3(306.003, -568.511, 63.181), -- Center of the area for checking player position
            floors = {
                [0] = {height = 64.159, ipls = {"johanni_pillbox_e03_01_milo_"}},
                [1] = {height = 68.162, ipls = {"johanni_pillbox_e03_02_milo_"}},
                [2] = {height = 60.025, ipls = {"johanni_pillbox_e03_03_milo_"}}
            }
        },
        opium = {
            resourceName = "tstudio_opium_nights", -- Added name for debug purposes
            center = vector3(-720.0305, -2268.00635, 16.2695923), -- Center of the area for checking player position
            floors = {
                [0] = {
                    height = 28.00,
                    ipls = {
                        "johanni_opium_penthouse_e01_milo_",
                        "johanni_opium_hallway_e01_milo_",
                        "johanni_opium_hotel_e01_r01_milo_",
                        "johanni_opium_hotel_e01_r02_milo_",
                        "johanni_opium_hotel_e01_r03_milo_",
                        "johanni_opium_hotel_e01_r04_milo_",
                        "johanni_opium_hotel_e01_r05_milo_",
                        "johanni_opium_hotel_e01_r06_milo_",
                        "johanni_opium_hotel_e01_r07_milo_",
                        "johanni_opium_hotel_e01_r08_milo_",
                        "johanni_opium_hotel_e01_r09_milo_",
                        "johanni_opium_hotel_e01_r10_milo_",
                        "johanni_opium_hotel_e01_r11_milo_",
                        "johanni_opium_hotel_e01_r12_milo_"
                    }
                },
                [1] = {
                    height = 38.14,
                    ipls = {
                        "johanni_opium_penthouse_e02_milo_",
                        "johanni_opium_hallway_e02_milo_",
                        "johanni_opium_hotel_e02_r01_milo_",
                        "johanni_opium_hotel_e02_r02_milo_",
                        "johanni_opium_hotel_e02_r03_milo_",
                        "johanni_opium_hotel_e02_r04_milo_",
                        "johanni_opium_hotel_e02_r05_milo_",
                        "johanni_opium_hotel_e02_r06_milo_",
                        "johanni_opium_hotel_e02_r07_milo_",
                        "johanni_opium_hotel_e02_r08_milo_",
                        "johanni_opium_hotel_e02_r09_milo_",
                        "johanni_opium_hotel_e02_r10_milo_",
                        "johanni_opium_hotel_e02_r11_milo_",
                        "johanni_opium_hotel_e02_r12_milo_"
                    }
                },
                [2] = {
                    height = 47.04,
                    ipls = {
                        "johanni_opium_penthouse_e03_milo_",
                        "johanni_opium_hallway_e03_milo_",
                        "johanni_opium_hotel_e03_r01_milo_",
                        "johanni_opium_hotel_e03_r02_milo_",
                        "johanni_opium_hotel_e03_r03_milo_",
                        "johanni_opium_hotel_e03_r04_milo_",
                        "johanni_opium_hotel_e03_r05_milo_",
                        "johanni_opium_hotel_e03_r06_milo_",
                        "johanni_opium_hotel_e03_r07_milo_",
                        "johanni_opium_hotel_e03_r08_milo_",
                        "johanni_opium_hotel_e03_r09_milo_",
                        "johanni_opium_hotel_e03_r10_milo_",
                        "johanni_opium_hotel_e03_r11_milo_",
                        "johanni_opium_hotel_e03_r12_milo_"
                    }
                },
                [3] = {
                    height = 55.88,
                    ipls = {
                        "johanni_opium_penthouse_e04_milo_",
                        "johanni_opium_hallway_e04_milo_",
                        "johanni_opium_hotel_e04_r01_milo_",
                        "johanni_opium_hotel_e04_r02_milo_",
                        "johanni_opium_hotel_e04_r03_milo_",
                        "johanni_opium_hotel_e04_r04_milo_",
                        "johanni_opium_hotel_e04_r05_milo_",
                        "johanni_opium_hotel_e04_r06_milo_",
                        "johanni_opium_hotel_e04_r07_milo_",
                        "johanni_opium_hotel_e04_r08_milo_",
                        "johanni_opium_hotel_e04_r09_milo_",
                        "johanni_opium_hotel_e04_r10_milo_",
                        "johanni_opium_hotel_e04_r11_milo_",
                        "johanni_opium_hotel_e04_r12_milo_"
                    }
                },
                [4] = {
                    height = 64.55,
                    ipls = {
                        "johanni_opium_penthouse_e05_milo_",
                        "johanni_opium_hallway_e05_milo_",
                        "johanni_opium_hotel_e05_r01_milo_",
                        "johanni_opium_hotel_e05_r02_milo_",
                        "johanni_opium_hotel_e05_r03_milo_",
                        "johanni_opium_hotel_e05_r04_milo_",
                        "johanni_opium_hotel_e05_r05_milo_",
                        "johanni_opium_hotel_e05_r06_milo_",
                        "johanni_opium_hotel_e05_r07_milo_",
                        "johanni_opium_hotel_e05_r08_milo_",
                        "johanni_opium_hotel_e05_r09_milo_",
                        "johanni_opium_hotel_e05_r10_milo_",
                        "johanni_opium_hotel_e05_r11_milo_",
                        "johanni_opium_hotel_e05_r12_milo_"
                    }
                },
                [5] = {
                    height = 73.35,
                    ipls = {
                        "johanni_opium_penthouse_e06_milo_",
                        "johanni_opium_hallway_e06_milo_",
                        "johanni_opium_hotel_e06_r01_milo_",
                        "johanni_opium_hotel_e06_r02_milo_",
                        "johanni_opium_hotel_e06_r03_milo_",
                        "johanni_opium_hotel_e06_r04_milo_",
                        "johanni_opium_hotel_e06_r05_milo_",
                        "johanni_opium_hotel_e06_r06_milo_",
                        "johanni_opium_hotel_e06_r07_milo_",
                        "johanni_opium_hotel_e06_r08_milo_",
                        "johanni_opium_hotel_e06_r09_milo_",
                        "johanni_opium_hotel_e06_r10_milo_",
                        "johanni_opium_hotel_e06_r11_milo_",
                        "johanni_opium_hotel_e06_r12_milo_"
                    }
                }
            }
        },
        peaktower_apa = {
            resourceName = "tstudio_peak_towers_zdlc_apartments", -- Added name for debug purposes
            center = vector3(57.393196, -930.921143, 192.874359), -- Center of the area for checking player position
            floors = {
                [0] = {
                    height = 192.874359, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor1_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor1_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor1_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor1_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor1_r2_milo",
                    },
                },
                [1] = {
                    height = 197.643738, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor2_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor2_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor2_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor2_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor2_r2_milo",
                    },
                },
                [2] = {
                    height = 202.043030, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor3_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor3_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor3_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor3_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor3_r2_milo",
                    },
                },
                [3] = {
                    height = 206.442368, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor4_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor4_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor4_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor4_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor4_r2_milo",
                    },
                },
                [4] = {
                    height = 237.238556, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor6_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor6_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor6_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor6_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor6_r2_milo",
                    },
                },
                [5] = {
                    height = 241.637894, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor7_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor7_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor7_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor7_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor7_r2_milo",
                    },
                },
                [6] = {
                    height = 246.037231, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor8_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor8_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor8_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor8_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor8_r2_milo",
                    },
                },
                [7] = {
                    height = 250.436569, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor9_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor9_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor9_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor9_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor9_r2_milo",
                    },
                },
                [8] = {
                    height = 254.835907, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor10_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor10_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor10_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor10_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor10_r2_milo",
                    },
                },
                [9] = {
                    height = 281.231873, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor11_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor11_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor11_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor11_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor11_r2_milo",
                    },
                },
                [10] = {
                    height = 285.631256, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor12_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor12_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor12_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor12_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor12_r2_milo",
                    },
                },
                [11] = {
                    height = 290.030670, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor13_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor13_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor13_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor13_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor13_r2_milo",
                    },
                },
                [12] = {
                    height = 294.430054, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor14_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor14_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor14_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor14_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor14_r2_milo",
                    },
                },
                [13] = {
                    height = 298.829437, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor15_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor15_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor15_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor15_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor15_r2_milo",
                    },
                },
            }
        },
    },

    -- Interior blocking configurations
    -- Each interior can be configured with the following properties:
    -- enabled: Whether this interior blocking is enabled (REQUIRED)
    -- coords: The coordinates of the interior (OPTIONAL - required for name-based blocking, optional for IPL-only)
    -- name: The interior name to disable via GetInteriorAtCoordsWithType (OPTIONAL)
    -- ipl: The IPL name to remove via RemoveIpl (OPTIONAL)
    --
    -- Three usage patterns:
    -- 1. Name only:     { enabled = true, name = "v_genbank", coords = vec3(...) }
    --                   Tries to disable interior by name, then removes IPL by name (coords required)
    -- 2. Name + IPL:    { enabled = true, name = "uniqx_flecca_col", ipl = "uniqx_flecca_l3_milo_", coords = vec3(...) }
    --                   Tries to disable interior by name, then removes IPL by different ipl name (coords required)
    -- 3. IPL only:      { enabled = true, ipl = "rc12b_default" }
    --                   Skips interior disabling, only removes IPL (coords optional, removed globally)
    Interiors = {
        ["tstudio_tattoo_studio"] = {
            [1] = { enabled = true, name = "v_tattoo", coords = vec3(-3171.2937, 1076.24451, 19.8303947) },
            [2] = { enabled = true, name = "v_tattoo", coords = vec3(322.967865, 181.942917, 102.587761) },
            [3] = { enabled = true, name = "v_tattoo", coords = vec3(1323.765, -1653.43164, 51.27684) },
            [4] = { enabled = true, name = "v_tattoo", coords = vec3(-1153.18408, -1427.0127, 3.955685) },
        },
        ["tstudio_ammunation"] = {
            [1] = { enabled = true, name = "v_gun", coords = vec3(821.144043, -2154.8916, 28.61892) },      -- Cypress
            [2] = { enabled = true, name = "v_gun2", coords = vec3(843.2987, -1028.10669, 27.1947746) },    -- LaMesa
            [3] = { enabled = true, name = "v_gun", coords = vec3(10.9070005, -1105.65833, 28.7969322) },   -- Legion
            [4] = { enabled = true, name = "v_gun2", coords = vec3(247.371582, -47.245163, 68.9409943) },   -- Hawick
            [5] = { enabled = true, name = "v_gun2", coords = vec3(-1310.87659, -392.009644, 35.6957169) }, -- MorningWood
            [6] = { enabled = true, name = "v_gun2", coords = vec3(-663.1717, -940.758057, 20.8291473) },   -- Little Seoul
            [7] = { enabled = true, name = "v_gun2", coords = vec3(-3167.29614, 1084.70984, 19.8386574) },  -- Chumash
            [8] = { enabled = true, name = "v_gun2", coords = vec3(2568.834, 299.788116, 107.734818) },     -- East Highway
            [9] = { enabled = true, name = "v_gun2", coords = vec3(1696.95251, 3755.445, 33.7052574) },     -- Sandy Shores
            [10] = { enabled = true, name = "v_gun2", coords = vec3(-327.1706, 6079.257, 30.4546967) },     -- Paleto Bay
            [11] = { enabled = true, name = "v_gun2", coords = vec3(-1114.84509, 2693.80957, 17.55406) }    -- Route 68
        },
        ["tstudio_fleeca"] = {
            [1] = { enabled = true, name = "v_genbank", coords = vec3(-355.435852, -48.5326, 48.1063843) },    -- Vinewood
            [2] = { enabled = true, name = "v_genbank", coords = vec3(309.74646, -277.644165, 53.2345963) },   -- Vinewood (Lower Level)
            [3] = { enabled = true, name = "v_genbank", coords = vec3(145.416824, -1039.277, 28.4378834) },    -- Legion Square
            [4] = { enabled = true, name = "v_genbank", coords = vec3(-1216.7616, -333.000763, 36.85084) },    -- Movie Studio
            [5] = { enabled = true, name = "hei_generic_bank_dlc", coords = vec3(-2962.59131, 478.238037, 14.7668953) },  -- West Highway
            [6] = { enabled = true, name = "v_genbank", coords = vec3(1179.74475, 2706.985, 37.15784) }        -- Sandy Shores
        },
        ["tstudio_pillbox_md"] = {
            [1] = { enabled = true, name = "rc12b_default", ipl = "rc12b_default", coords = vec3(307.1680, -590.807, 43.280) },    -- Pillbox Hill
        },
        ["tstudio_mrpd"] = {
            [1] = { enabled = true, name = "hei_heist_police_dlc", ipl = "hei_heist_police_dlc", coords = vec3(442.429565, -985.067, 29.8852863) },    -- preparation for MRPD
            [2] = { enabled = true, name = "v_policehub", ipl = "v_policehub", coords = vec3(442.429565, -985.0669, 29.8852863) },    -- preparation for MRPD        },
        },
        ["tstudio_peak_towers"] = {
            [1] = { enabled = true, ipl = "uniqx_flecca_lods_l3" },    -- TStudio Fleeca Legion Square LOD (IPL-only, no coords)
            [2] = { enabled = true, name = "uniqx_flecca_col", ipl = "uniqx_flecca_l3_milo_", coords = vec3(145.416824, -1039.277, 28.4378834) },    -- TStudio Fleeca Legion Square
            [3] = { enabled = true, name = "v_genbank", coords = vec3(145.416824, -1039.277, 28.4378834) },    -- Legion Square
        },
    },

    -- Smart Switch configurations for interactive prop-based entity set toggling
    -- Each entry defines a set of props that, when interacted with, open a RageUI menu
    -- to toggle room-specific entity sets (e.g., blinds) in the current interior.
    -- Only active when the specified resource is started.
    SmartSwitches = {
        peaktowers_apa = {
            resourceName = "tstudio_peak_towers_zdlc_apartments",
            center = vector3(57.393196, -930.921143, 192.874359),
            props = {
                "tstudio_hg_peaktowers_apa_smartswitch",
                "tstudio_hg_peaktowers_apa_smartswitchmain"
            },
            interactionRange = 1.0,
            outlineColor = {r = 128, g = 64, b = 0},
            roomBlinds = {
                main    = { open = "apa_main_blinds_open",    closed = "apa_main_blinds_closed" },
                bedroom = { open = "apa_bedroom_blinds_open",  closed = "apa_bedroom_blinds_closed" },
                closet  = { open = "apa_closet_blinds_open",   closed = "apa_closet_blinds_closed" },
            },
            header = {
                topColor = {r = 128, g = 64, b = 0},
                bottomColor = {r = 64, g = 32, b = 0}
            },
            locales = {
                ["en"] = {
                    ["menu-title"] = "Smart Home",
                    ["menu-description"] = "Blind Controls",
                    ["help-notify"] = "~INPUT_CONTEXT~ Smart Home Controls",
                    ["open-blinds"] = "Open Blinds",
                    ["close-blinds"] = "Close Blinds",
                },
                ["de"] = {
                    ["menu-title"] = "Smart Home",
                    ["menu-description"] = "Jalousie Steuerung",
                    ["help-notify"] = "~INPUT_CONTEXT~ Smart Home Steuerung",
                    ["open-blinds"] = "Jalousien öffnen",
                    ["close-blinds"] = "Jalousien schließen",
                }
            }
        }
    },

    -- Dry Volume configurations
    -- Dry volumes prevent water from rendering in specific areas
    -- Each project can have multiple dry volumes defined by min/max coordinates
    DryVolumes = {
        ["tstudio_missionrow_park"] = {
            {
                name = "Mission Row Park IPL Patch Fix 1",
                minX = 337.012115,
                minY = -1013.49805,
                minZ = -100.221939,
                maxX = 353.21637,
                maxY = -992.301636,
                maxZ = -97.20087
            },
            {
                name = "Mission Row Park IPL Patch Fix 2",
                minX = 281.538,
                minY = -1002.9624,
                minZ = -100.007484,
                maxX = 313.910767,
                maxY = -984.104553,
                maxZ = -90.30185
            }
        },
        ["tstudio_peak_towers"] = {
            {
                name = "Peak Towers Horizon Link Fix",
                minX = 89.316505,
                minY = -1046.967651,
                minZ = 27.972031,
                maxX = 153.239319,
                maxY = -990.951172,
                maxZ = 208.340683
            }
        }
        -- Example for multiple dry volumes in one project:
        -- ["project_name"] = {
        --     {
        --         name = "Area 1",
        --         minX = x1, minY = y1, minZ = z1,
        --         maxX = x2, maxY = y2, maxZ = z2
        --     },
        --     {
        --         name = "Area 2",
        --         minX = x1, minY = y1, minZ = z1,
        --         maxX = x2, maxY = y2, maxZ = z2
        --     }
        -- }
    }
}
