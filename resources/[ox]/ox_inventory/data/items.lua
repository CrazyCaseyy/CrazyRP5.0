return {
    ['testburger'] = {
        label = 'Test Burger',
        weight = 220,
        degrade = 60,
        client = {
            image = 'burger_chicken.png',
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            export = 'ox_inventory_examples.testburger'
        },
        server = {
            export = 'ox_inventory_examples.testburger',
            test = 'what an amazingly delicious burger, amirite?'
        },
        buttons = {
            {
                label = 'Lick it',
                action = function(slot)
                    print('You licked the burger')
                end
            },
            {
                label = 'Squeeze it',
                action = function(slot)
                    print('You squeezed the burger :(')
                end
            },
            {
                label = 'What do you call a vegan burger?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('A misteak.')
                end
            },
            {
                label = 'What do frogs like to eat with their hamburgers?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('French flies.')
                end
            },
            {
                label = 'Why were the burger and fries running?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('Because they\'re fast food.')
                end
            }
        },
        consume = 0.3
    },

    ['bandage'] = {
        label = 'Bandage',
        weight = 115,
    },

    ['burger'] = {
        label = 'Burger',
        weight = 220,
        client = {
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            notification = 'You ate a delicious burger'
        },
    },

    ['sprunk'] = {
        label = 'Sprunk',
        weight = 350,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            notification = 'You quenched your thirst with a sprunk'
        }
    },

    ['parachute'] = {
        label = 'Parachute',
        weight = 8000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 1500
        }
    },

    ['garbage'] = {
        label = 'Garbage',
    },

    ['paperbag'] = {
        label = 'Paper Bag',
        weight = 1,
        stack = false,
        close = false,
        consume = 0
    },

    ['panties'] = {
        label = 'Knickers',
        weight = 10,
        consume = 0,
        client = {
            status = { thirst = -100000, stress = -25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
            usetime = 2500,
        }
    },

    ['lockpick'] = {
        label = 'Lockpick',
        weight = 160,
        rarity = 'uncommon',
    },

    ['phone'] = {
        label = 'Phone',
        weight = 190,
        stack = false,
        consume = 0,
        client = {
            add = function(total)
                if total > 0 then
                    pcall(function() return exports.npwd:setPhoneDisabled(false) end)
                end
            end,

            remove = function(total)
                if total < 1 then
                    pcall(function() return exports.npwd:setPhoneDisabled(true) end)
                end
            end
        }
    },

    ['mustard'] = {
        label = 'Mustard',
        weight = 500,
        client = {
            status = { hunger = 25000, thirst = 25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
            usetime = 2500,
            notification = 'You... drank mustard'
        }
    },

    ['water'] = {
        label = 'Water',
        weight = 500,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
            usetime = 2500,
            cancel = true,
            notification = 'You drank some refreshing water'
        }
    },

    ['armour'] = {
        label = 'Bulletproof Vest',
        weight = 3000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 3500
        }
    },

    ['clothing'] = {
        label = 'Clothing',
        consume = 0,
    },

    ['money'] = {
        label = 'Money',
        rarity = 'common',
    },

    ['black_money'] = {
        label = 'Dirty Money',
        rarity = 'uncommon',
    },

    ['id_card'] = {
        label = 'Identification Card',
        rarity = 'common',
    },

    ['driver_license'] = {
        label = 'Drivers License',
        rarity = 'common',
    },

    ['weaponlicense'] = {
        label = 'Weapon License',
        rarity = 'common',
    },

    ['lawyerpass'] = {
        label = 'Lawyer Pass',
        rarity = 'common',
    },

    ['radio'] = {
        label = 'Radio',
        weight = 1000,
        allowArmed = true,
        consume = 0,
        rarity = 'common',
        client = {
            event = 'mm_radio:client:use'
        }
    },

    ['jammer'] = {
        label = 'Radio Jammer',
        weight = 10000,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:usejammer'
        }
    },

    ['radiocell'] = {
        label = 'AAA Cells',
        weight = 1000,
        stack = true,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:recharge'
        }
    },

    ['advancedlockpick'] = {
        label = 'Advanced Lockpick',
        weight = 500,
        rarity = 'uncommon',
    },

    ['screwdriverset'] = {
        label = 'Screwdriver Set',
        weight = 500,
        rarity = 'uncommon',
    },

    ['electronickit'] = {
        label = 'Electronic Kit',
        weight = 500,
        rarity = 'uncommon',
    },


    ['diamond_ring'] = {
        label = 'Diamond',
        weight = 1500,
        rarity = 'rare',
    },

    ['rolex'] = {
        label = 'Golden Watch',
        weight = 1500,
        rarity = 'rare',
    },

    ['goldbar'] = {
        label = 'Gold Bar',
        weight = 1500,
        rarity = 'epic',
    },

    ['goldchain'] = {
        label = 'Golden Chain',
        weight = 1500,
        rarity = 'rare',
    },

    ['crack_baggy'] = {
        label = 'Crack Baggy',
        weight = 100,
    },

    ['cokebaggy'] = {
        label = 'Bag of Coke',
        weight = 100,
    },

    ['coke_brick'] = {
        label = 'Coke Brick',
        weight = 2000,
    },

    ['coke_small_brick'] = {
        label = 'Coke Package',
        weight = 1000,
    },

    ['xtcbaggy'] = {
        label = 'Bag of Ecstasy',
        weight = 100,
    },

    ['meth'] = {
        label = 'Methamphetamine',
        weight = 100,
    },

    ['oxy'] = {
        label = 'Oxycodone',
        weight = 100,
    },

    ['weed_ak47'] = {
        label = 'AK47 2g',
        weight = 200,
    },

    ['weed_ak47_seed'] = {
        label = 'AK47 Seed',
        weight = 1,
    },

    ['weed_skunk'] = {
        label = 'Skunk 2g',
        weight = 200,
    },

    ['weed_skunk_seed'] = {
        label = 'Skunk Seed',
        weight = 1,
    },

    ['weed_amnesia'] = {
        label = 'Amnesia 2g',
        weight = 200,
    },

    ['weed_amnesia_seed'] = {
        label = 'Amnesia Seed',
        weight = 1,
    },

    ['weed_og-kush'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_og-kush_seed'] = {
        label = 'OGKush Seed',
        weight = 1,
    },

    ['weed_white-widow'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_white-widow_seed'] = {
        label = 'White Widow Seed',
        weight = 1,
    },

    ['weed_purple-haze'] = {
        label = 'Purple Haze 2g',
        weight = 200,
    },

    ['weed_purple-haze_seed'] = {
        label = 'Purple Haze Seed',
        weight = 1,
    },

    ['weed_brick'] = {
        label = 'Weed Brick',
        weight = 2000,
    },

    ['weed_nutrition'] = {
        label = 'Plant Fertilizer',
        weight = 2000,
    },

    ['joint'] = {
        label = 'Joint',
        weight = 200,
    },

    ['rolling_paper'] = {
        label = 'Rolling Paper',
        weight = 0,
    },

    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
    },

    ['firstaid'] = {
        label = 'First Aid',
        weight = 2500,
    },

    ['ifaks'] = {
        label = 'Individual First Aid Kit',
        weight = 2500,
    },

    ['painkillers'] = {
        label = 'Painkillers',
        weight = 400,
    },

    ['firework1'] = {
        label = '2Brothers',
        weight = 1000,
    },

    ['firework2'] = {
        label = 'Poppelers',
        weight = 1000,
    },

    ['firework3'] = {
        label = 'WipeOut',
        weight = 1000,
    },

    ['firework4'] = {
        label = 'Weeping Willow',
        weight = 1000,
    },

    ['steel'] = {
        label = 'Steel',
        weight = 100,
    },

    ['rubber'] = {
        label = 'Rubber',
        weight = 100,
    },

    ['metalscrap'] = {
        label = 'Metal Scrap',
        weight = 100,
    },

    ['iron'] = {
        label = 'Iron',
        weight = 100,
    },

    ['copper'] = {
        label = 'Copper',
        weight = 100,
    },

    ['aluminum'] = {
        label = 'Aluminium',
        weight = 100,
    },

    ['plastic'] = {
        label = 'Plastic',
        weight = 100,
    },

    ['glass'] = {
        label = 'Glass',
        weight = 100,
    },

    ['gatecrack'] = {
        label = 'Gatecrack',
        weight = 1000,
        rarity = 'legendary',
    },

    ['cryptostick'] = {
        label = 'Crypto Stick',
        weight = 100,
        rarity = 'legendary',
    },

    ['trojan_usb'] = {
        label = 'Trojan USB',
        weight = 100,
    },

    ['toaster'] = {
        label = 'Toaster',
        weight = 5000,
    },

    ['small_tv'] = {
        label = 'Small TV',
        weight = 100,
    },

    ['security_card_01'] = {
        label = 'Security Card A',
        weight = 100,
        rarity = 'rare',
    },

    ['security_card_02'] = {
        label = 'Security Card B',
        weight = 100,
        rarity = 'rare',
    },

    ['drill'] = {
        label = 'Drill',
        weight = 5000,
        rarity = 'epic',
    },

    ['thermite'] = {
        label = 'Thermite',
        weight = 1000,
        rarity = 'epic',
    },

    ['diving_gear'] = {
        label = 'Diving Gear',
        weight = 30000,
    },

    ['diving_fill'] = {
        label = 'Diving Tube',
        weight = 3000,
    },

    ['antipatharia_coral'] = {
        label = 'Antipatharia',
        weight = 1000,
    },

    ['dendrogyra_coral'] = {
        label = 'Dendrogyra',
        weight = 1000,
    },

    ['jerry_can'] = {
        label = 'Jerrycan',
        weight = 3000,
    },

    ['nitrous'] = {
        label = 'Nitrous',
        weight = 1000,
    },

    ['wine'] = {
        label = 'Wine',
        weight = 500,
    },

    ['grape'] = {
        label = 'Grape',
        weight = 10,
    },

    ['grapejuice'] = {
        label = 'Grape Juice',
        weight = 200,
    },

    ['coffee'] = {
        label = 'Coffee',
        weight = 200,
    },

    ['vodka'] = {
        label = 'Vodka',
        weight = 500,
    },

    ['whiskey'] = {
        label = 'Whiskey',
        weight = 200,
    },

    ['beer'] = {
        label = 'Beer',
        weight = 200,
    },

    ['sandwich'] = {
        label = 'Sandwich',
        weight = 200,
    },

    ['walking_stick'] = {
        label = 'Walking Stick',
        weight = 1000,
    },

    ['lighter'] = {
        label = 'Lighter',
        weight = 200,
    },

    ['binoculars'] = {
        label = 'Binoculars',
        weight = 800,
    },

    ['stickynote'] = {
        label = 'Sticky Note',
        weight = 0,
    },

    ['empty_evidence_bag'] = {
        label = 'Empty Evidence Bag',
        weight = 200,
    },

    ['filled_evidence_bag'] = {
        label = 'Filled Evidence Bag',
        weight = 200,
    },

    ['harness'] = {
        label = 'Harness',
        weight = 200,
    },

    ['handcuffs'] = {
        label = 'Handcuffs',
        weight = 200,
    },

    -- Jim-Mechanic --

["mechanic_tools"] = {
    label = "Mechanic tools", weight = 0, stack = false, close = true, description = "Needed for vehicle repairs",
    client = { image = "mechanic_tools.png", event = "jim-mechanic:client:Repair:Check" }
},
["toolbox"] = {
    label = "Toolbox", weight = 0, stack = false, close = true, description = "Needed for Performance part removal",
    client = { image = "toolbox.png", event = "jim-mechanic:client:Menu" }
},
["ducttape"] = {
    label = "Duct Tape", weight = 0, stack = false, close = true, description = "Good for quick fixes",
    client = { image = "bodyrepair.png", event = "jim-mechanic:quickrepair" }
},
['mechboard'] = { label = 'Mechanic Sheet', weight = 0, stack = false, close = true,
    buttons = {
        { 	label = 'View List',
            action = function(slot)
                local items = exports.ox_inventory:Search('slots', 'mechboard')
                for _, v in pairs(items) do
                    if (v.slot == slot) then
                        local item = v
                        item.info = item.metadata["info"] or {}
                        TriggerEvent("jim-mechanic:client:giveList", item)
                        exports.ox_inventory:closeInventory()
                        break
                    end
                end
            end
        },
        { 	label = 'Copy Parts List',
            action = function(slot)
                local items = exports.ox_inventory:Search('slots', 'mechboard')
                for _, v in pairs(items) do
                    if (v.slot == slot) then
                        lib.setClipboard(v.metadata.info.vehlist)
                        break
                    end
                end
            end
        },
        { 	label = 'Copy Platedsdf Number',
            action = function(slot)
                local items = exports.ox_inventory:Search('slots', 'mechboard')
                for _, v in pairs(items) do
                    if (v.slot == slot) then
                        lib.setClipboard(v.metadata.info.vehplate)
                        break
                    end
                end
            end
        },
        {	label = 'Copy Vehicle Model',
            action = function(slot)
                local items = exports.ox_inventory:Search('slots', 'mechboard')
                for _, v in pairs(items) do
                    if (v.slot == slot) then
                        lib.setClipboard(v.metadata.info.veh) break
                    end
                end
            end
        },
    },
    client = {
        event = "jim-mechanic:client:giveList"
    }
},
--Performance
["turbo"] = {
    label = "Supercharger Turbo", weight = 0, stack = false, close = true, description = "Who doesn't need a 65mm Turbo??",
    client = { image = "turbo.png", event = "jim-mechanic:client:applyTurbo", remove = false },
},
["car_armor"] = {
    label = "Vehicle Armor", weight = 0, stack = false, close = true, description = "",
    client = { image = "armour.png", event = "jim-mechanic:client:applyArmour", remove = false },
},
["nos"] = {
    label = "NOS Bottle", weight = 0, stack = false, close = true, description = "A full bottle of NOS",
    client = { image = "nos.png", event = "jim-mechanic:client:applyNOS", },
},
["noscan"] = {
    label = "Empty NOS Bottle", weight = 0, stack = true, close = true, description = "An Empty bottle of NOS",
    client = { image = "noscan.png", }
},
["noscolour"] = {
    label = "NOS Colour Injector", weight = 0, stack = true, close = true, description = "Make that purge spray",
    client = { image = "noscolour.png", event = "jim-mechanic:client:NOS:rgbORhex", },
},

["engine1"] = {
    label = "Tier 1 Engine", weight = 0, stack = false, close = true, description = "",
    client = { image = "engine1.png",  event = "jim-mechanic:client:applyEngine", level = 0, remove = false },
},
["engine2"] = {
    label = "Tier 2 Engine", weight = 0, stack = false, close = true, description = "",
    client = { image = "engine2.png",  event = "jim-mechanic:client:applyEngine", level = 1, remove = false },
},
["engine3"] = {
    label = "Tier 3 Engine", weight = 0, stack = false, close = true, description = "",
    client = { image = "engine3.png",  event = "jim-mechanic:client:applyEngine", level = 2, remove = false },
},
["engine4"] = {
    label = "Tier 4 Engine", weight = 0, stack = false, close = true, description = "",
    client = { image = "engine4.png",  event = "jim-mechanic:client:applyEngine", level = 3, remove = false },
},
["engine5"] = {
    label = "Tier 5 Engine", weight = 0, stack = false, close = true, description = "",
    client = { image = "engine5.png",  event = "jim-mechanic:client:applyEngine", level = 4, remove = false },
},

["transmission1"] = {
    label = "Tier 1 Transmission", weight = 0, stack = false, close = true, description = "",
    client = { image = "transmission1.png",  event = "jim-mechanic:client:applyTransmission", level = 0, remove = false },
},
["transmission2"] = {
    label = "Tier 2 Transmission", weight = 0, stack = false, close = true, description = "",
    client = { image = "transmission2.png",  event = "jim-mechanic:client:applyTransmission", level = 1, remove = false },
},
["transmission3"] = {
    label = "Tier 3 Transmission", weight = 0, stack = false, close = true, description = "",
    client = { image = "transmission3.png",  event = "jim-mechanic:client:applyTransmission", level = 2, remove = false },
},
["transmission4"] = {
    label = "Tier 4 Transmission", weight = 0, stack = false, close = true, description = "",
    client = { image = "transmission4.png",  event = "jim-mechanic:client:applyTransmission", level = 3, remove = false },
},

["brakes1"] = {
    label = "Tier 1 Brakes", weight = 0, stack = false, close = true, description = "",
    client = { image = "brakes1.png",  event = "jim-mechanic:client:applyBrakes", level = 0, remove = false },
},
["brakes2"] = {
    label = "Tier 2 Brakes", weight = 0, stack = false, close = true, description = "",
    client = { image = "brakes2.png",  event = "jim-mechanic:client:applyBrakes", level = 1, remove = false },
},
["brakes3"] = {
    label = "Tier 3 Brakes", weight = 0, stack = false, close = true, description = "",
    client = { image = "brakes3.png",  event = "jim-mechanic:client:applyBrakes", level = 2, remove = false },
},

["suspension1"] = {
    label = "Tier 1 Suspension", weight = 0, stack = false, close = true, description = "",
    client = { image = "suspension1.png", event = "jim-mechanic:client:applySuspension",  level = 0, remove = false },
},
["suspension2"] = {
    label = "Tier 2 Suspension", weight = 0, stack = false, close = true, description = "",
    client = { image = "suspension2.png", event = "jim-mechanic:client:applySuspension", level = 1, remove = false },
},
["suspension3"] = {
    label = "Tier 3 Suspension", weight = 0, stack = false, close = true, description = "",
    client = { image = "suspension3.png", event = "jim-mechanic:client:applySuspension", level = 2, remove = false },
},
["suspension4"] = {
    label = "Tier 4 Suspension", weight = 0, stack = false, close = true, description = "",
    client = { image = "suspension4.png", event = "jim-mechanic:client:applySuspension", level = 3, remove = false },
},
["suspension5"] = {
    label = "Tier 5 Suspension", weight = 0, stack = false, close = true, description = "",
    client = { image = "suspension5.png", event = "jim-mechanic:client:applySuspension", level = 4, remove = false },
},

["bprooftires"] = {
    label = "Bulletproof Tires", weight = 0, stack = false, close = true, description = "",
    client = { image = "bprooftires.png", event = "jim-mechanic:client:applyBulletProof", remove = false },
},
["drifttires"] = {
    label = "Drift Tires", weight = 0, stack = false, close = true, description = "",
    client = { image = "drifttires.png", event = "jim-mechanic:client:applyDrift", remove = false },
},

["oilp1"] = {
    label = "Tier 1 Oil Pump", weight = 0, stack = false, close = true, description = "",
    client = { image = "oilp1.png", event = "jim-mechanic:client:applyExtraPart", level = 1, mod = "oilp", remove = false },
},
["oilp2"] = {
    label = "Tier 2 Oil Pump", weight = 0, stack = false, close = true, description = "",
    client = { image = "oilp2.png", event = "jim-mechanic:client:applyExtraPart", level = 2, mod = "oilp", remove = false },
},
["oilp3"] = {
    label = "Tier 3 Oil Pump", weight = 0, stack = false, close = true, description = "",
    client = { image = "oilp3.png", event = "jim-mechanic:client:applyExtraPart", level = 3, mod = "oilp", remove = false },
},

["drives1"] = {
    label = "Tier 1 Drive Shaft", weight = 0, stack = false, close = true, description = "",
    client = { image = "drives1.png", event = "jim-mechanic:client:applyExtraPart", level = 1, mod = "drives", remove = false },
},
["drives2"] = {
    label = "Tier 2 Drive Shaft", weight = 0, stack = false, close = true, description = "",
    client = { image = "drives2.png", event = "jim-mechanic:client:applyExtraPart", level = 2, mod = "drives", remove = false },
},
["drives3"] = {
    label = "Tier 3 Drive Shaft", weight = 0, stack = false, close = true, description = "",
    client = { image = "drives3.png", event = "jim-mechanic:client:applyExtraPart", level = 3, mod = "drives", remove = false },
},

["cylind1"] = {
    label = "Tier 1 Cylinder Head", weight = 0, stack = false, close = true, description = "",
    client = { image = "cylind1.png", event = "jim-mechanic:client:applyExtraPart", level = 1, mod = "cylind", remove = false },
},
["cylind2"] = {
    label = "Tier 2 Cylinder Head", weight = 0, stack = false, close = true, description = "",
    client = { image = "cylind2.png", event = "jim-mechanic:client:applyExtraPart", level = 2, mod = "cylind", remove = false },
},
["cylind3"] = {
    label = "Tier 3 Cylinder Head", weight = 0, stack = false, close = true, description = "",
    client = { image = "cylind3.png", event = "jim-mechanic:client:applyExtraPart", level = 3, mod = "cylind", remove = false },
},

["cables1"] = {
    label = "Tier 1 Battery Cables", weight = 0, stack = false, close = true, description = "",
    client = { image = "cables1.png", event = "jim-mechanic:client:applyExtraPart", level = 1, mod = "cables", remove = false },
},
["cables2"] = {
    label = "Tier 2 Battery Cables", weight = 0, stack = false, close = true, description = "",
    client = { image = "cables2.png", event = "jim-mechanic:client:applyExtraPart", level = 2, mod = "cables", remove = false },
},
["cables3"] = {
    label = "Tier 3 Battery Cables", weight = 0, stack = false, close = true, description = "",
    client = { image = "cables3.png", event = "jim-mechanic:client:applyExtraPart", level = 3, mod = "cables", remove = false },
},

["fueltank1"] = {
    label = "Tier 1 Fuel Tank", weight = 0, stack = false, close = true, description = "",
    client = { image = "fueltank1.png", event = "jim-mechanic:client:applyExtraPart", level = 1, mod = "fueltank", remove = false },
},
["fueltank2"] = {
    label = "Tier 2 Fuel Tank", weight = 0, stack = false, close = true, description = "",
    client = { image = "fueltank2.png", event = "jim-mechanic:client:applyExtraPart", level = 2, mod = "fueltank", remove = false },
},
["fueltank3"] = {
    label = "Tier 3 Fuel Tank", weight = 0, stack = false, close = true, description = "",
    client = { image = "fueltank3.png", event = "jim-mechanic:client:applyExtraPart", level = 3, mod = "fueltank", remove = false },
},

["antilag"] = {
    label = "AntiLag", weight = 0, stack = false, close = true, description = "",
    client = { image = "antiLag.png", event = "jim-mechanic:client:applyAntiLag", remove = false },
},

["underglow_controller"] = {
    label = "Neon Controller", weight = 0, stack = false, close = true, description = "",
    client = { image = "underglow_controller.png", event = "jim-mechanic:client:neonMenu", },
},
["headlights"] = {
    label = "Xenon Headlights", weight = 0, stack = false, close = true, description = "",
    client = { image = "headlights.png", event = "jim-mechanic:client:applyXenons", },
},

["tint_supplies"] = {
    label = "Window Tint Kit", weight = 0, stack = false, close = true, description = "",
    client = { image = "tint_supplies.png", event = "jim-mechanic:client:Cosmetic:Check", },
},

["customplate"] = {
    label = "Customized Plates", weight = 0, stack = false, close = true, description = "",
    client = { image = "plate.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["hood"] = {
    label = "Vehicle Hood", weight = 0, stack = false, close = true, description = "",
    client = { image = "hood.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["roof"] = {
    label = "Vehicle Roof", weight = 0, stack = false, close = true, description = "",
    client = { image = "roof.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["spoiler"] = {
    label = "Vehicle Spoiler", weight = 0, stack = false, close = true, description = "",
    client = { image = "spoiler.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["bumper"] = {
    label = "Vehicle Bumper", weight = 0, stack = false, close = true, description = "",
    client = { image = "bumper.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["skirts"] = {
    label = "Vehicle Skirts", weight = 0, stack = false, close = true, description = "",
    client = { image = "skirts.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["exhaust"] = {
    label = "Vehicle Exhaust", weight = 0, stack = false, close = true, description = "",
    client = { image = "exhaust.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["seat"] = {
    label = "Seat Cosmetics", weight = 0, stack = false, close = true, description = "",
    client = { image = "seat.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["rollcage"] = {
    label = "Roll Cage", weight = 0, stack = false, close = true, description = "",
    client = { image = "rollcage.png", event = "jim-mechanic:client:Cosmetic:Check", },
},

["rims"] = {
    label = "Custom Wheel Rims", weight = 0, stack = false, close = true, description = "",
    client = { image = "rims.png", event = "jim-mechanic:client:Rims:Check", },
},

["livery"] = {
    label = "Livery Roll", weight = 0, stack = false, close = true, description = "",
    client = { image = "livery.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["paintcan"] = {
    label = "Vehicle Spray Can", weight = 0, stack = false, close = true, description = "",
    client = { image = "spraycan.png", event = "jim-mechanic:client:Paints:Check", },
},
["tires"] = {
    label = "Drift Smoke Tires", weight = 0, stack = false, close = true, description = "",
    client = { image = "tires.png", event = "jim-mechanic:client:Tires:Check", },
},

["horn"] = {
    label = "Custom Vehicle Horn", weight = 0, stack = false, close = true, description = "",
    client = { image = "horn.png", event = "jim-mechanic:client:Cosmetic:Check", },
},

["internals"] = {
    label = "Internal Cosmetics", weight = 0, stack = false, close = true, description = "",
    client = { image = "internals.png", event = "jim-mechanic:client:Cosmetic:Check", },
},
["externals"] = {
    label = "Exterior Cosmetics", weight = 0, stack = false, close = true, description = "",
    client = { image = "mirror.png", event = "jim-mechanic:client:Cosmetic:Check", },
},

["newoil"] = {
    label = "Car Oil", weight = 0, stack = false, close = true, description = "",
    client = { image = "caroil.png", },
},
["sparkplugs"] = {
    label = "Spark Plugs", weight = 0, stack = false, close = true, description = "",
    client = { image = "sparkplugs.png", },
},
["carbattery"] = {
    label = "Car Battery", weight = 0, stack = false, close = true, description = "",
    client = { image = "carbattery.png", },
},
["axleparts"] = {
    label = "Axle Parts", weight = 0, stack = false, close = true, description = "",
    client = { image = "axleparts.png", },
},
["sparetire"] = {
    label = "Spare Tire", weight = 0, stack = false, close = true, description = "",
    client = { image = "sparetire.png", event = "jim-mechanic:client:wheelRepair" },
},

["harness"] = {
    label = "Race Harness", weight = 0, stack = true, close = true, description = "Racing Harness so no matter what you stay in the car",
    client = { image = "harness.png", event = "jim-mechanic:client:applyHarness", remove = false },
},

["manual"] = {
    label = "Manual Transmission", weight = 0, stack = true, close = true, description = "Manual Transmission change for vehicles",
    client = { image = "manual.png", event = "jim-mechanic:client:applyManual", remove = false },
},

["underglow"] = {
    label = "Underglow LEDS", weight = 0, stack = true, close = true, description = "Underglow addition for vehicles",
    client = { image = "underglow.png", event = "jim-mechanic:client:applyUnderglow", remove = false },
},

["stancerkit"] = {
    label = "Stancer Kit", weight = 0, stack = true, close = true, description = "Stancer Kit for vehicles",
    client = { image = "stancerkit.png", event = "jim-mechanic:client:stancerMenu", remove = false },
},

["newplate"] = {
    label = "New Plate", weight = 250, stack = false, close = true, description = "A Customizable licence plate.",
    client = { image = "newplate.png", event = "jim-mechanic:client:setplate:Menu" }
},

-- Replace these if these are already installed

["cleaningkit"] = {
    label = "Cleaning Kit", weight = 0, stack = true, close = true, description = "A microfiber cloth with some soap will let your car sparkle again!",
   client = { image = "cleaningkit.png", event = "jim-mechanic:client:cleanVehicle"},
},
["repairkit"] = {
    label = "Repairkit", weight = 0, stack = true, close = true, description = "A nice toolbox with stuff to repair your vehicle",
   client = { image = "repairkit.png", event = "jim-mechanic:vehFailure:RepairVehicle", item = "repairkit", full = false },
},
["advancedrepairkit"] = {
    label = "Advanced Repairkit", weight = 0, stack = true, close = true, description = "A nice toolbox with stuff to repair your vehicle",
   client = { image = "advancedkit.png", event = "jim-mechanic:vehFailure:RepairVehicle", item = "advancedrepairkit", full = true },
},

["cash_rolls"] = {
    label = "Cash Rolls", weight = 250, stack = true, close = true, description = "Rolled-up bills taken from a store register",
    client = { image = "cash_rolls.png" },
},

["cash_band"] = {
    label = "Cash Band", weight = 400, stack = true, close = true, rarity = "rare", description = "A bundled stack of bills cracked out of a store safe",
    client = { image = "cashband.png" },
},

-- Burger Shot: raw stock, bought by employees from the business account at the supply point
["bs_bun"] = {
    label = "Burger Bun", weight = 40, stack = true, close = true, rarity = "common",
    client = { image = "burgerbun.png" },
},
["bs_patty"] = {
    label = "Patty", weight = 90, stack = true, close = true, rarity = "common",
    client = { image = "burgerpatty.png" },
},
["bs_lettuce"] = {
    label = "Lettuce", weight = 20, stack = true, close = true, rarity = "common",
    client = { image = "lettuce.png" },
},
["bs_tomato"] = {
    label = "Tomato", weight = 20, stack = true, close = true, rarity = "common",
    client = { image = "tomato_raw.png" },
},
["bs_onion"] = {
    label = "Onion", weight = 20, stack = true, close = true, rarity = "common",
    client = { image = "burger-onion.png" },
},
["bs_potato"] = {
    label = "Potato", weight = 50, stack = true, close = true, rarity = "common",
    client = { image = "burger-slicedpotato.png" },
},
["bs_cup"] = {
    label = "Cup", weight = 15, stack = true, close = true, rarity = "common",
    client = { image = "cup.png" },
},

-- Burger Shot: finished menu items, crafted from the above and sold at the register
["bs_bleeder"] = {
    label = "The Bleeder", weight = 260, stack = true, close = true, rarity = "uncommon",
    client = { image = "burger-bleeder.png", status = { hunger = 150000 }, anim = "eating", prop = "burger", usetime = 2500, notification = "You ate a Bleeder" },
},
["bs_heartstopper"] = {
    label = "Heart Stopper", weight = 320, stack = true, close = true, rarity = "uncommon",
    client = { image = "burger-heartstopper.png", status = { hunger = 220000 }, anim = "eating", prop = "burger", usetime = 2500, notification = "You ate a Heart Stopper" },
},
["bs_meatfree"] = {
    label = "Meat Free", weight = 240, stack = true, close = true, rarity = "common",
    client = { image = "burger-meatfree.png", status = { hunger = 130000 }, anim = "eating", prop = "burger", usetime = 2500, notification = "You ate a Meat Free" },
},
["bs_torpedo"] = {
    label = "Torpedo", weight = 280, stack = true, close = true, rarity = "rare",
    client = { image = "burger-torpedo.png", status = { hunger = 180000 }, anim = "eating", prop = "burger", usetime = 2500, notification = "You ate a Torpedo" },
},
["bs_moneyshot"] = {
    label = "Money Shot", weight = 300, stack = true, close = true, rarity = "epic",
    client = { image = "burger-moneyshot.png", status = { hunger = 200000 }, anim = "eating", prop = "burger", usetime = 2500, notification = "You ate a Money Shot" },
},
["bs_fries"] = {
    label = "Shot Fries", weight = 150, stack = true, close = true, rarity = "common",
    client = { image = "burger-fries.png", status = { hunger = 80000 }, anim = "eating", prop = "burger", usetime = 2000, notification = "You ate some fries" },
},
["bs_onionrings"] = {
    label = "Shot Rings", weight = 150, stack = true, close = true, rarity = "common",
    client = { image = "burger-shotrings.png", status = { hunger = 80000 }, anim = "eating", prop = "burger", usetime = 2000, notification = "You ate some onion rings" },
},
["bs_nuggets"] = {
    label = "Shot Nuggets", weight = 170, stack = true, close = true, rarity = "uncommon",
    client = { image = "burger-shotnuggets.png", status = { hunger = 90000 }, anim = "eating", prop = "burger", usetime = 2000, notification = "You ate some nuggets" },
},
["bs_sprunk"] = {
    label = "Sprunk", weight = 350, stack = true, close = true, rarity = "common",
    client = { image = "sprunk.png", status = { thirst = 180000 }, anim = { dict = "mp_player_intdrink", clip = "loop_bottle" }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500, notification = "You drank a Sprunk" },
},
["bs_ecola"] = {
    label = "eCola", weight = 350, stack = true, close = true, rarity = "common",
    client = { image = "cola.png", status = { thirst = 180000 }, anim = { dict = "mp_player_intdrink", clip = "loop_bottle" }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500, notification = "You drank an eCola" },
},
["bs_milkshake"] = {
    label = "Milkshake", weight = 380, stack = true, close = true, rarity = "rare",
    client = { image = "burger-milkshake.png", status = { thirst = 220000, hunger = 40000 }, anim = { dict = "mp_player_intdrink", clip = "loop_bottle" }, prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) }, usetime = 2500, notification = "You drank a Milkshake" },
},

-- crazy-reputation: opens the civilian reputation tablet UI.
["tablet"] = {
    label = "Tablet",
    weight = 500,
    stack = false,
    close = true,
    client = { image = "tablet.png" },
},

    -- ══════════ crazy-kitchen: auto-registered crafting items (placeholder labels/weights, tune as needed) ══════════
    ['ad_berry_coulis'] = {
        label = 'Berry Coulis',
        weight = 100,
    },

    ['ad_black_pepper'] = {
        label = 'Black Pepper',
        weight = 100,
    },

    ['ad_carbonara'] = {
        label = 'Carbonara',
        weight = 100,
    },

    ['ad_carrot_celery'] = {
        label = 'Carrot Celery',
        weight = 100,
    },

    ['ad_cherry_tomatoes'] = {
        label = 'Cherry Tomatoes',
        weight = 100,
    },

    ['ad_chilli_flakes'] = {
        label = 'Chilli Flakes',
        weight = 100,
    },

    ['ad_cocoa_powder'] = {
        label = 'Cocoa Powder',
        weight = 100,
    },

    ['ad_dried_herbs'] = {
        label = 'Dried Herbs',
        weight = 100,
    },

    ['ad_eggs'] = {
        label = 'Eggs',
        weight = 100,
    },

    ['ad_espresso'] = {
        label = 'Espresso',
        weight = 100,
    },

    ['ad_fresh_basil'] = {
        label = 'Fresh Basil',
        weight = 100,
    },

    ['ad_garlic_cloves'] = {
        label = 'Garlic Cloves',
        weight = 100,
    },

    ['ad_gelatin'] = {
        label = 'Gelatin',
        weight = 100,
    },

    ['ad_ground_beef'] = {
        label = 'Ground Beef',
        weight = 100,
    },

    ['ad_heavy_cream'] = {
        label = 'Heavy Cream',
        weight = 100,
    },

    ['ad_house_wine'] = {
        label = 'House Wine',
        weight = 100,
    },

    ['ad_ladyfingers'] = {
        label = 'Ladyfingers',
        weight = 100,
    },

    ['ad_margherita_pizza'] = {
        label = 'Margherita Pizza',
        weight = 100,
    },

    ['ad_margherita_slice'] = {
        label = 'Margherita Slice',
        weight = 100,
    },

    ['ad_marsala_wine'] = {
        label = 'Marsala Wine',
        weight = 100,
    },

    ['ad_mascarpone'] = {
        label = 'Mascarpone',
        weight = 100,
    },

    ['ad_mozzarella'] = {
        label = 'Mozzarella',
        weight = 100,
    },

    ['ad_olive_oil'] = {
        label = 'Olive Oil',
        weight = 100,
    },

    ['ad_pancetta'] = {
        label = 'Pancetta',
        weight = 100,
    },

    ['ad_panna_cotta'] = {
        label = 'Panna Cotta',
        weight = 100,
    },

    ['ad_parmesan'] = {
        label = 'Parmesan',
        weight = 100,
    },

    ['ad_pecorino'] = {
        label = 'Pecorino',
        weight = 100,
    },

    ['ad_penne'] = {
        label = 'Penne',
        weight = 100,
    },

    ['ad_penne_arrabbiata'] = {
        label = 'Penne Arrabbiata',
        weight = 100,
    },

    ['ad_pizza_dough'] = {
        label = 'Pizza Dough',
        weight = 100,
    },

    ['ad_red_wine'] = {
        label = 'Red Wine',
        weight = 100,
    },

    ['ad_sea_salt'] = {
        label = 'Sea Salt',
        weight = 100,
    },

    ['ad_spaghetti'] = {
        label = 'Spaghetti',
        weight = 100,
    },

    ['ad_spaghetti_bolognese'] = {
        label = 'Spaghetti Bolognese',
        weight = 100,
    },

    ['ad_sparkling_water'] = {
        label = 'Sparkling Water',
        weight = 100,
    },

    ['ad_tiramisu'] = {
        label = 'Tiramisu',
        weight = 100,
    },

    ['ad_tomato_sauce'] = {
        label = 'Tomato Sauce',
        weight = 100,
    },

    ['ad_vanilla_pod'] = {
        label = 'Vanilla Pod',
        weight = 100,
    },

    ['aluminium_bar'] = {
        label = 'Aluminium Bar',
        weight = 250,
    },

    ['bs_bacon_bits'] = {
        label = 'Bacon Bits',
        weight = 100,
    },

    ['bs_beef_patty'] = {
        label = 'Beef Patty',
        weight = 100,
    },

    ['bs_breadcrumbs'] = {
        label = 'Breadcrumbs',
        weight = 100,
    },

    ['bs_burger_bun'] = {
        label = 'Burger Bun',
        weight = 100,
    },

    ['bs_burger_sauce'] = {
        label = 'Burger Sauce',
        weight = 100,
    },

    ['bs_buttermilk'] = {
        label = 'Buttermilk',
        weight = 100,
    },

    ['bs_cheese_sauce'] = {
        label = 'Cheese Sauce',
        weight = 100,
    },

    ['bs_cheese_slice'] = {
        label = 'Cheese Slice',
        weight = 100,
    },

    ['bs_classic_burger'] = {
        label = 'Classic Burger',
        weight = 100,
    },

    ['bs_cold_brew'] = {
        label = 'Cold Brew',
        weight = 100,
    },

    ['bs_coleslaw_mix'] = {
        label = 'Coleslaw Mix',
        weight = 100,
    },

    ['bs_cooking_oil'] = {
        label = 'Cooking Oil',
        weight = 100,
    },

    ['bs_crispy_chicken'] = {
        label = 'Crispy Chicken',
        weight = 100,
    },

    ['bs_diced_onion'] = {
        label = 'Diced Onion',
        weight = 100,
    },

    ['bs_double_smash'] = {
        label = 'Double Smash',
        weight = 100,
    },

    ['bs_ice_cream_mix'] = {
        label = 'Ice Cream Mix',
        weight = 100,
    },

    ['bs_ice_cubes'] = {
        label = 'Ice Cubes',
        weight = 100,
    },

    ['bs_iced_coffee'] = {
        label = 'Iced Coffee',
        weight = 100,
    },

    ['bs_lettuce_tomato'] = {
        label = 'Lettuce Tomato',
        weight = 100,
    },

    ['bs_loaded_fries'] = {
        label = 'Loaded Fries',
        weight = 100,
    },

    ['bs_mayo'] = {
        label = 'Mayo',
        weight = 100,
    },

    ['bs_milk'] = {
        label = 'Milk',
        weight = 100,
    },

    ['bs_pickles'] = {
        label = 'Pickles',
        weight = 100,
    },

    ['bs_raw_chicken'] = {
        label = 'Raw Chicken',
        weight = 100,
    },

    ['bs_raw_potato'] = {
        label = 'Raw Potato',
        weight = 100,
    },

    ['bs_salt_pepper'] = {
        label = 'Salt Pepper',
        weight = 100,
    },

    ['bs_smoked_paprika'] = {
        label = 'Smoked Paprika',
        weight = 100,
    },

    ['bs_soda'] = {
        label = 'Soda',
        weight = 100,
    },

    ['bs_soft_serve'] = {
        label = 'Soft Serve',
        weight = 100,
    },

    ['bs_special_sauce'] = {
        label = 'Special Sauce',
        weight = 100,
    },

    ['bs_vanilla_syrup'] = {
        label = 'Vanilla Syrup',
        weight = 100,
    },

    ['bs_wafer_cone'] = {
        label = 'Wafer Cone',
        weight = 100,
    },

    ['bs_whipped_cream'] = {
        label = 'Whipped Cream',
        weight = 100,
    },

    ['carclean'] = {
        label = 'Carclean',
        weight = 300,
    },

    ['carpolish'] = {
        label = 'Carpolish',
        weight = 300,
    },

    ['carpolish_high'] = {
        label = 'Carpolish High',
        weight = 350,
    },

    ['copper_bar'] = {
        label = 'Copper Bar',
        weight = 250,
    },

    ['glue'] = {
        label = 'Glue',
        weight = 50,
    },

    ['gold_bar'] = {
        label = 'Gold Bar',
        weight = 250,
    },

    ['h_berry'] = {
        label = 'Berry',
        weight = 100,
    },

    ['h_berry_mix'] = {
        label = 'Berry Mix',
        weight = 100,
    },

    ['h_brownie'] = {
        label = 'Brownie',
        weight = 100,
    },

    ['h_raw_shrimp'] = {
        label = 'Raw Shrimp',
        weight = 100,
    },

    ['h_rings'] = {
        label = 'Rings',
        weight = 100,
    },

    ['h_shrimp'] = {
        label = 'Shrimp',
        weight = 100,
    },

    ['h_slider'] = {
        label = 'Slider',
        weight = 100,
    },

    ['h_slush'] = {
        label = 'Slush',
        weight = 100,
    },

    ['h_sun'] = {
        label = 'Sun',
        weight = 100,
    },

    ['h_tots'] = {
        label = 'Tots',
        weight = 100,
    },

    ['hab_ach'] = {
        label = 'Ach',
        weight = 100,
    },

    ['hab_bkb'] = {
        label = 'Bkb',
        weight = 100,
    },

    ['hab_choc'] = {
        label = 'Choc',
        weight = 100,
    },

    ['hab_fb'] = {
        label = 'Fb',
        weight = 100,
    },

    ['hab_lst'] = {
        label = 'Lst',
        weight = 100,
    },

    ['hab_rose'] = {
        label = 'Rose',
        weight = 100,
    },

    ['hab_tof'] = {
        label = 'Tof',
        weight = 100,
    },

    ['iron_bar'] = {
        label = 'Iron Bar',
        weight = 250,
    },

    ['kk_ayran'] = {
        label = 'Ayran',
        weight = 100,
    },

    ['kk_baklava'] = {
        label = 'Baklava',
        weight = 100,
    },

    ['kk_basmati_rice'] = {
        label = 'Basmati Rice',
        weight = 100,
    },

    ['kk_butter'] = {
        label = 'Butter',
        weight = 100,
    },

    ['kk_chicken_breast'] = {
        label = 'Chicken Breast',
        weight = 100,
    },

    ['kk_chicken_wrap'] = {
        label = 'Chicken Wrap',
        weight = 100,
    },

    ['kk_chilli_sauce'] = {
        label = 'Chilli Sauce',
        weight = 100,
    },

    ['kk_cinnamon'] = {
        label = 'Cinnamon',
        weight = 100,
    },

    ['kk_crushed_pistachios'] = {
        label = 'Crushed Pistachios',
        weight = 100,
    },

    ['kk_doner_kebab'] = {
        label = 'Doner Kebab',
        weight = 100,
    },

    ['kk_filo_pastry'] = {
        label = 'Filo Pastry',
        weight = 100,
    },

    ['kk_flatbread'] = {
        label = 'Flatbread',
        weight = 100,
    },

    ['kk_fresh_mint'] = {
        label = 'Fresh Mint',
        weight = 100,
    },

    ['kk_garlic_sauce'] = {
        label = 'Garlic Sauce',
        weight = 100,
    },

    ['kk_grilled_pepper'] = {
        label = 'Grilled Pepper',
        weight = 100,
    },

    ['kk_honey'] = {
        label = 'Honey',
        weight = 100,
    },

    ['kk_kebab_spice_mix'] = {
        label = 'Kebab Spice Mix',
        weight = 100,
    },

    ['kk_kofta_mix'] = {
        label = 'Kofta Mix',
        weight = 100,
    },

    ['kk_lamb_cubes'] = {
        label = 'Lamb Cubes',
        weight = 100,
    },

    ['kk_lamb_meat'] = {
        label = 'Lamb Meat',
        weight = 100,
    },

    ['kk_lemon'] = {
        label = 'Lemon',
        weight = 100,
    },

    ['kk_mint_tea'] = {
        label = 'Mint Tea',
        weight = 100,
    },

    ['kk_mixed_grill'] = {
        label = 'Mixed Grill',
        weight = 100,
    },

    ['kk_olive_oil'] = {
        label = 'Olive Oil',
        weight = 100,
    },

    ['kk_pudding_rice'] = {
        label = 'Pudding Rice',
        weight = 100,
    },

    ['kk_rice_pudding'] = {
        label = 'Rice Pudding',
        weight = 100,
    },

    ['kk_rose_water'] = {
        label = 'Rose Water',
        weight = 100,
    },

    ['kk_salad_mix'] = {
        label = 'Salad Mix',
        weight = 100,
    },

    ['kk_shish_kebab'] = {
        label = 'Shish Kebab',
        weight = 100,
    },

    ['kk_skewers'] = {
        label = 'Skewers',
        weight = 100,
    },

    ['kk_sugar'] = {
        label = 'Sugar',
        weight = 100,
    },

    ['kk_sumac'] = {
        label = 'Sumac',
        weight = 100,
    },

    ['kk_tzatziki'] = {
        label = 'Tzatziki',
        weight = 100,
    },

    ['kk_wrap_bread'] = {
        label = 'Wrap Bread',
        weight = 100,
    },

    ['kk_yoghurt'] = {
        label = 'Yoghurt',
        weight = 100,
    },

    ['lead_bar'] = {
        label = 'Lead Bar',
        weight = 250,
    },

    ['lithium_bar'] = {
        label = 'Lithium Bar',
        weight = 250,
    },

    ['old_cloth'] = {
        label = 'Old Cloth',
        weight = 100,
    },

    ['p_boil'] = {
        label = 'Boil',
        weight = 100,
    },

    ['p_cal'] = {
        label = 'Cal',
        weight = 100,
    },

    ['p_coco'] = {
        label = 'Coco',
        weight = 100,
    },

    ['p_coconut'] = {
        label = 'Coconut',
        weight = 100,
    },

    ['p_crem'] = {
        label = 'Crem',
        weight = 100,
    },

    ['p_fillet'] = {
        label = 'Fillet',
        weight = 100,
    },

    ['p_lobster'] = {
        label = 'Lobster',
        weight = 100,
    },

    ['p_pina'] = {
        label = 'Pina',
        weight = 100,
    },

    ['p_pineapple'] = {
        label = 'Pineapple',
        weight = 100,
    },

    ['p_raw_fish'] = {
        label = 'Raw Fish',
        weight = 100,
    },

    ['p_raw_lobster'] = {
        label = 'Raw Lobster',
        weight = 100,
    },

    ['p_raw_squid'] = {
        label = 'Raw Squid',
        weight = 100,
    },

    ['p_rum'] = {
        label = 'Rum',
        weight = 100,
    },

    ['p_seafood_mix'] = {
        label = 'Seafood Mix',
        weight = 100,
    },

    ['p_sex'] = {
        label = 'Sex',
        weight = 100,
    },

    ['p_shark'] = {
        label = 'Shark',
        weight = 100,
    },

    ['p_straw'] = {
        label = 'Straw',
        weight = 100,
    },

    ['p_strawberry'] = {
        label = 'Strawberry',
        weight = 100,
    },

    ['p_tai'] = {
        label = 'Tai',
        weight = 100,
    },

    ['p_tropical_syrup'] = {
        label = 'Tropical Syrup',
        weight = 100,
    },

    ['p_vodka'] = {
        label = 'Vodka',
        weight = 100,
    },

    ['pp_00_flour'] = {
        label = '00 Flour',
        weight = 100,
    },

    ['pp_bbq_chicken_pizza_slice'] = {
        label = 'Bbq Chicken Pizza Slice',
        weight = 100,
    },

    ['pp_bbq_sauce'] = {
        label = 'Bbq Sauce',
        weight = 100,
    },

    ['pp_cheddar'] = {
        label = 'Cheddar',
        weight = 100,
    },

    ['pp_chilli_flakes'] = {
        label = 'Chilli Flakes',
        weight = 100,
    },

    ['pp_chilli_oil'] = {
        label = 'Chilli Oil',
        weight = 100,
    },

    ['pp_cooked_chicken'] = {
        label = 'Cooked Chicken',
        weight = 100,
    },

    ['pp_diavola_pizza_slice'] = {
        label = 'Diavola Pizza Slice',
        weight = 100,
    },

    ['pp_dried_oregano'] = {
        label = 'Dried Oregano',
        weight = 100,
    },

    ['pp_dried_yeast'] = {
        label = 'Dried Yeast',
        weight = 100,
    },

    ['pp_espresso_beans'] = {
        label = 'Espresso Beans',
        weight = 100,
    },

    ['pp_espresso_cup'] = {
        label = 'Espresso Cup',
        weight = 100,
    },

    ['pp_flavour_paste'] = {
        label = 'Flavour Paste',
        weight = 100,
    },

    ['pp_fresh_basil'] = {
        label = 'Fresh Basil',
        weight = 100,
    },

    ['pp_gelato'] = {
        label = 'Gelato',
        weight = 100,
    },

    ['pp_gelato_base'] = {
        label = 'Gelato Base',
        weight = 100,
    },

    ['pp_gorgonzola'] = {
        label = 'Gorgonzola',
        weight = 100,
    },

    ['pp_honey_drizzle'] = {
        label = 'Honey Drizzle',
        weight = 100,
    },

    ['pp_icing_sugar'] = {
        label = 'Icing Sugar',
        weight = 100,
    },

    ['pp_lemon_juice'] = {
        label = 'Lemon Juice',
        weight = 100,
    },

    ['pp_limonata'] = {
        label = 'Limonata',
        weight = 100,
    },

    ['pp_mixed_peppers'] = {
        label = 'Mixed Peppers',
        weight = 100,
    },

    ['pp_mozzarella'] = {
        label = 'Mozzarella',
        weight = 100,
    },

    ['pp_nduja'] = {
        label = 'Nduja',
        weight = 100,
    },

    ['pp_nutella_calzone'] = {
        label = 'Nutella Calzone',
        weight = 100,
    },

    ['pp_nutella_jar'] = {
        label = 'Nutella Jar',
        weight = 100,
    },

    ['pp_olive_oil'] = {
        label = 'Olive Oil',
        weight = 100,
    },

    ['pp_parmesan'] = {
        label = 'Parmesan',
        weight = 100,
    },

    ['pp_pepperoni'] = {
        label = 'Pepperoni',
        weight = 100,
    },

    ['pp_pepperoni_pizza_slice'] = {
        label = 'Pepperoni Pizza Slice',
        weight = 100,
    },

    ['pp_pizza_base'] = {
        label = 'Pizza Base',
        weight = 100,
    },

    ['pp_pizza_dough'] = {
        label = 'Pizza Dough',
        weight = 100,
    },

    ['pp_quattro_formaggi_slice'] = {
        label = 'Quattro Formaggi Slice',
        weight = 100,
    },

    ['pp_red_onion'] = {
        label = 'Red Onion',
        weight = 100,
    },

    ['pp_sea_salt'] = {
        label = 'Sea Salt',
        weight = 100,
    },

    ['pp_sliced_banana'] = {
        label = 'Sliced Banana',
        weight = 100,
    },

    ['pp_sparkling_water'] = {
        label = 'Sparkling Water',
        weight = 100,
    },

    ['pp_spring_onion'] = {
        label = 'Spring Onion',
        weight = 100,
    },

    ['pp_sugar_syrup'] = {
        label = 'Sugar Syrup',
        weight = 100,
    },

    ['pp_tomato_base'] = {
        label = 'Tomato Base',
        weight = 100,
    },

    ['pp_whole_milk'] = {
        label = 'Whole Milk',
        weight = 100,
    },

    ['repair_part_axle'] = {
        label = 'Repair Part Axle',
        weight = 600,
    },

    ['repair_part_brakes'] = {
        label = 'Repair Part Brakes',
        weight = 600,
    },

    ['repair_part_brakes_hg'] = {
        label = 'Repair Part Brakes (High Grade)',
        weight = 600,
    },

    ['repair_part_clutch'] = {
        label = 'Repair Part Clutch',
        weight = 600,
    },

    ['repair_part_clutch_hg'] = {
        label = 'Repair Part Clutch (High Grade)',
        weight = 600,
    },

    ['repair_part_electronics'] = {
        label = 'Repair Part Electronics',
        weight = 600,
    },

    ['repair_part_injectors'] = {
        label = 'Repair Part Injectors',
        weight = 600,
    },

    ['repair_part_injectors_hg'] = {
        label = 'Repair Part Injectors (High Grade)',
        weight = 600,
    },

    ['repair_part_rad'] = {
        label = 'Repair Part Rad',
        weight = 600,
    },

    ['repair_part_rad_hg'] = {
        label = 'Repair Part Rad (High Grade)',
        weight = 600,
    },

    ['repair_part_transmission'] = {
        label = 'Repair Part Transmission',
        weight = 600,
    },

    ['repair_part_transmission_hg'] = {
        label = 'Repair Part Transmission (High Grade)',
        weight = 600,
    },

    ['repairkitadv'] = {
        label = 'Repairkitadv',
        weight = 500,
    },

    ['silver_bar'] = {
        label = 'Silver Bar',
        weight = 250,
    },

    ['tech_trash'] = {
        label = 'Tech Trash',
        weight = 150,
    },

    ['tin_bar'] = {
        label = 'Tin Bar',
        weight = 250,
    },

    ['upgrade_brakes1'] = {
        label = 'Upgrade Brakes 1',
        weight = 1500,
    },

    ['upgrade_brakes2'] = {
        label = 'Upgrade Brakes 2',
        weight = 1500,
    },

    ['upgrade_brakes3'] = {
        label = 'Upgrade Brakes 3',
        weight = 1500,
    },

    ['upgrade_engine1'] = {
        label = 'Upgrade Engine 1',
        weight = 1500,
    },

    ['upgrade_engine2'] = {
        label = 'Upgrade Engine 2',
        weight = 1500,
    },

    ['upgrade_engine3'] = {
        label = 'Upgrade Engine 3',
        weight = 1500,
    },

    ['upgrade_suspension1'] = {
        label = 'Upgrade Suspension 1',
        weight = 1500,
    },

    ['upgrade_suspension2'] = {
        label = 'Upgrade Suspension 2',
        weight = 1500,
    },

    ['upgrade_suspension3'] = {
        label = 'Upgrade Suspension 3',
        weight = 1500,
    },

    ['upgrade_transmission1'] = {
        label = 'Upgrade Transmission 1',
        weight = 1500,
    },

    ['upgrade_transmission2'] = {
        label = 'Upgrade Transmission 2',
        weight = 1500,
    },

    ['upgrade_transmission3'] = {
        label = 'Upgrade Transmission 3',
        weight = 1500,
    },

    ['upgrade_turbo'] = {
        label = 'Upgrade Turbo',
        weight = 1500,
    },

}
