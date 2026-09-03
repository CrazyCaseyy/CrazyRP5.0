Config = {}

Config.Debug            = false
Config.MaxBundlesPerBiz = 20
Config.PaymentMethods   = { cash = true, card = true }

-- Percentage of each paid order handed straight to the staff member who took
-- it, as cash. Replaces the original prp_tablet:recordSale commission
-- tracker, which isn't part of this server - paid directly in server.lua
-- instead of through an external tablet resource. Set to 0 to disable.
Config.CommissionPercent = 10

Config.StaffJobPermissions = {
    paparattos = { job = 'paparattos',     grade = 0 },
    burgershot = { job = 'burgershot',     grade = 0 },
    aldente = { job = 'aldente',     grade = 0 },
    kebab   = { job = 'kebab',   grade = 0 },
    habibi  = { job = 'habibi', grade = 0 },
    pearls  = { job = 'pearls',  grade = 0 },
    hornys  = { job = 'hornys',  grade = 0 },

    stroke = { job = 'stroke',     grade = 0 },
    bennys = { job = 'bennys',     grade = 0 },
    tuner = { job = 'tuner',     grade = 0 },

    seaton = { job = 'seaton',     grade = 0 },

    hornys = { job = 'hornys',     grade = 0 },

    hornbills = { job = 'hornbills',     grade = 0 },
    mooreclub = { job = 'mooreclub',     grade = 0 },
}

Config.Businesses = {

    paparattos = {
        label = 'Paparattos',

        blip = {
            sprite = 267, 
            colour = 1,
        },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(-1191.579, -1402.697, 4.7566661),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 215.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1190.715, -1402.499, 4.690823, 28.858783),
                },
            },
            {
                registerZone = {
                    coords  = vector3(-1195.271, -1403.107, 4.7712211),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 215.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1194.676, -1403.959, 4.6783146, 334.36911),
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(-1188.989, -1401.284, 4.6908235, 45.039089),
            },
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(-1194.164, -1404.708, 4.6783151, 180.59251),
            },
        },

        products = {
            { item = 'pp_pepperoni_pizza',   label = 'Pepperoni Pizza',       price = 18, icon = '🍕', limit = 100, category = 'food'   },
            { item = 'pp_bbq_chicken_pizza', label = 'BBQ Chicken Pizza',     price = 20, icon = '🍕', limit = 100, category = 'food'   },
            { item = 'pp_quattro_formaggi',  label = 'Quattro Formaggi Pizza',price = 20, icon = '🍕', limit = 100, category = 'food'   },
            { item = 'pp_diavola_pizza',     label = 'Diavola Pizza',         price = 18, icon = '🍕', limit = 100, category = 'food'   },
            { item = 'pp_nutella_calzone',   label = 'Chocolate Calzone',     price = 14, icon = '🫓', limit = 100, category = 'food'   },
            { item = 'pp_gelato',            label = 'Gelato Scoops',         price = 8,  icon = '🍨', limit = 100, category = 'food'   },
            { item = 'pp_limonata',          label = 'Italian Limonata',      price = 6,  icon = '🍋', limit = 100, category = 'drinks' },
            { item = 'pp_espresso_cup',      label = 'Espresso',              price = 5,  icon = '☕', limit = 100, category = 'drinks' },
        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(-1191.665, -1395.112, 4.8650608), -- update in-game
                size      = vector3(0.7, 0.6, 1.7),
                heading   = 215.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Oven Storage',
                coords    = vector3(-1193.093, -1394.766, 4.9549903), -- update in-game
                size      = vector3(0.7, 0.6, 1.7),
                heading   = 215.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Tray 1 ',
                coords    = vector3(-1192.186, -1403.298, 4.5282883), -- update in-game
                size      = vector3(0.5, 0.7, 0.5),
                heading   = 215.0,
                slots     = 10,
                weight    = 10000,
                staffOnly = false,
            },
            {
                label     = 'Tray 2',
                coords    = vector3(-1193.195, -1404.096, 4.5282883), -- update in-game
                size      = vector3(0.5, 0.7, 0.5),
                heading   = 215.0,
                slots     = 10,
                weight    = 10000,
                staffOnly = false,
            },
        },
    },
    burgershot = {
        label = 'Burgershot',

        blip = {
            sprite = 106,  -- fork & knife / restaurant
            colour = 17,   -- orange (fast food feel)
        },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(-1192.018, -894.5061, 14.166984),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 215.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1192.581, -893.4717, 13.984603, 130.01303),
                },
            },
            {
                registerZone = {
                    coords  = vector3(-1190.937, -896.1254, 14.166984),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 215.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1191.02, -895.5764, 13.984602, 130.01303),
                },
            },
            {
                registerZone = {
                    coords  = vector3(-1194.93, -892.1964, 14.166984),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 215.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1193.98, -892.9583, 13.984602, 130.01303),
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(-1193.039, -892.788, 13.984603, 172.75595),
            },
            
        },

        products = {
            { item = 'bs_classic_burger',  label = 'Classic Burger',       price = 12, icon = '🍔', limit = 100, category = 'food'  },
            { item = 'bs_double_smash',    label = 'Double Smash Burger',  price = 16, icon = '🍔', limit = 100, category = 'food'  },
            { item = 'bs_crispy_chicken',  label = 'Crispy Chicken Burger',price = 14, icon = '🍗', limit = 100, category = 'food'  },
            { item = 'bs_loaded_fries',    label = 'Loaded Fries',         price = 8,  icon = '🍟', limit = 100, category = 'food'  },

            { item = 'bs_milkshake',       label = 'Milkshake',            price = 6,  icon = '🥤', limit = 100, category = 'food'  },
            { item = 'bs_soft_serve',      label = 'Soft Serve Cone',      price = 4,  icon = '🍦', limit = 100, category = 'food'  },

            { item = 'bs_soda',            label = 'Fountain Soda',        price = 3,  icon = '🥤', limit = 100, category = 'drink' },
            { item = 'bs_iced_coffee',     label = 'Iced Coffee',          price = 5,  icon = '☕', limit = 100, category = 'drink' },
        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(-1202.87, -891.1967, 14.121631), -- update in-game
                size      = vector3(0.7, 0.6, 1.7),
                heading   = 215.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Oven Storage',
                coords    = vector3(-1201.211, -898.5117, 14.333507), -- update in-game
                size      = vector3(1.0, 1.6, 1.7),
                heading   = 215.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate Storage',
                coords    = vector3(-1196.251, -895.103, 14.378026), -- update in-game
                size      = vector3(1.7, 1.6, 0.8),
                heading   = 215.0,
                slots     = 25,
                weight    = 50000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate 2 Storage',
                coords    = vector3(-1193.819, -898.6843, 14.396049), -- update in-game
                size      = vector3(1.7, 1.6, 0.8),
                heading   = 215.0,
                slots     = 25,
                weight    = 50000,
                staffOnly = true,
            },
            {
                label     = 'Tray 1',
                coords    = vector3(-1194.488, -892.7051, 14.005917), -- update in-game
                size      = vector3(0.5, 0.7, 0.5),
                heading   = 215.0,
                slots     = 10,
                weight    = 10000,
                staffOnly = false,
            },
            {
                label     = 'Tray 2',
                coords    = vector3(-1192.349, -893.8994, 14.005917), -- update in-game
                size      = vector3(0.5, 0.7, 0.5),
                heading   = 215.0,
                slots     = 10,
                weight    = 10000,
                staffOnly = false,
            },
            {
                label     = 'Tray 3',
                coords    = vector3(-1190.439, -896.7109, 14.005917), -- update in-game
                size      = vector3(0.5, 0.7, 0.5),
                heading   = 215.0,
                slots     = 10,
                weight    = 10000,
                staffOnly = false,
            },
        },
    },
    aldente = {
        label = 'Al Dente',

        blip = {
            sprite = 76,  -- fork & knife / restaurant
            colour = 4,   -- gold (upscale fine dining)
        },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(92.030845, 11.069342, 68.757644),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(92.099906, 10.578106, 68.575462, 80.04537),
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(91.767822, 9.4831962, 68.575462, 84.072929),
            },
            
        },

        products = {
            -- [ FOOD ]
            { item = 'ad_spaghetti_bolognese', label = 'Spaghetti Bolognese',   price = 22, icon = '🍝', limit = 100, category = 'food'  },
            { item = 'ad_carbonara',           label = 'Spaghetti Carbonara',   price = 20, icon = '🍝', limit = 100, category = 'food'  },
            { item = 'ad_penne_arrabbiata',    label = 'Penne Arrabbiata',      price = 18, icon = '🍝', limit = 100, category = 'food'  },
            { item = 'ad_margherita_pizza',    label = 'Margherita Pizza',      price = 24, icon = '🍕', limit = 100, category = 'food'  },
            { item = 'ad_margherita_slice',    label = 'Margherita Pizza Slice',price = 8,  icon = '🍕', limit = 100, category = 'food'  },

            -- [ DESSERTS ]
            { item = 'ad_tiramisu',            label = 'Tiramisu',              price = 12, icon = '🍮', limit = 100, category = 'food'  },
            { item = 'ad_panna_cotta',         label = 'Panna Cotta',           price = 10, icon = '🍮', limit = 100, category = 'food'  },

            -- [ DRINKS ]
            { item = 'ad_house_wine',          label = 'House Wine',            price = 9,  icon = '🍷', limit = 100, category = 'drink' },
            { item = 'ad_sparkling_water',     label = 'Sparkling Water',       price = 5,  icon = '💧', limit = 100, category = 'drink' },
        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(83.843719, 12.589242, 68.857879), -- update in-game
                size      = vector3(1.2, 0.6, 1.7),
                heading   = 70.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Oven Storage',
                coords    = vector3(83.577041, 11.336174, 68.751602), -- update in-game
                size      = vector3(0.8, 0.4, 1.3),
                heading   = 70.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate',
                coords    = vector3(86.974746, 7.6976141, 68.63681), -- update in-game
                size      = vector3(2.5, 0.4, 1.0),
                heading   = 70.0,
                slots     = 25,
                weight    = 50000,
                staffOnly = true,
            },
            {
                label     = 'Tray',
                coords    = vector3(90.298461, 9.2648801, 68.616416), -- update in-game
                size      = vector3(1.4, 0.2, 1.0),
                heading   = 70.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },
    kebab = {
        label = 'Kebab King',

        blip = {
            sprite = 439,  -- fork & knife / restaurant
            colour = 5,   -- dark yellow / warm (kebab shop feel)
        },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(256.20837, -818.045, 30.198968),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(256.7915, -818.5473, 30.195306, -20.73709),
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(257.20272, -818.282, 30.195306, 225.30946),
            },
            
        },

        products = {
            -- [ FOOD ]
            { item = 'kk_doner_kebab',   label = 'Doner Kebab',          price = 14, icon = '🥙', limit = 100, category = 'food'  },
            { item = 'kk_shish_kebab',   label = 'Shish Kebab',          price = 16, icon = '🍢', limit = 100, category = 'food'  },
            { item = 'kk_chicken_wrap',  label = 'Chicken Shish Wrap',   price = 12, icon = '🌯', limit = 100, category = 'food'  },
            { item = 'kk_mixed_grill',   label = 'Mixed Grill Platter',  price = 28, icon = '🍖', limit = 100, category = 'food'  },

            -- [ DESSERTS ]
            { item = 'kk_baklava',       label = 'Baklava',              price = 8,  icon = '🍯', limit = 100, category = 'food'  },
            { item = 'kk_rice_pudding',  label = 'Sutlac (Rice Pudding)',price = 7,  icon = '🍮', limit = 100, category = 'food'  },

            -- [ DRINKS ]
            { item = 'kk_ayran',         label = 'Ayran',                price = 4,  icon = '🥛', limit = 100, category = 'drink' },
            { item = 'kk_mint_tea',      label = 'Mint Tea',             price = 4,  icon = '🍵', limit = 100, category = 'drink' },
        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(249.93463, -811.6556, 30.443027), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 50,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Oven Storage',
                coords    = vector3(253.0447, -814.1757, 30.407283), -- update in-game
                size      = vector3(0.4, 1.4, 1.0),
                heading   = 70.0,
                slots     = 50,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate',
                coords    = vector3(254.73323, -814.7056, 30.450195), -- update in-game
                size      = vector3(0.5, 0.6, 1.0),
                heading   = 70.0,
                slots     = 25,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate 2',
                coords    = vector3(255.81715, -815.1227, 30.450195), -- update in-game
                size      = vector3(0.5, 0.6, 1.0),
                heading   = 70.0,
                slots     = 25,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Tray',
                coords    = vector3(254.06628, -817.5453, 30.198968), -- update in-game
                size      = vector3(0.5, 2.4, 1.0),
                heading   = 70.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },

    habibi = {
        label = 'Habibi Kitchen',

        blip = {
            sprite = 439,
            colour = 22,
        },

        tills = {
            {
                registerZone = {
                    coords  = vector3(17.5277, -1602.777, 29.49109), -- TODO: update with actual coords
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 0.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,
                    coords = vector4(16.396665, -1602.149, 29.428939, 345.5639), -- TODO: update with actual coords
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,
                coords = vector4(15.842534, -1601.326, 29.428939, 347.62966), -- TODO: update with actual coords
            },
        },

        products = {
            -- [ FOOD ]
            { item = 'hab_fb',  label = 'Falafel Bowl',              price = 12, icon = '🥙', limit = 100, category = 'food'  },
            { item = 'hab_bkb', label = 'Beef Kebab Burrito',        price = 14, icon = '🌯', limit = 100, category = 'food'  },
            { item = 'hab_lst', label = 'Lamb Shawarma Tacos',       price = 14, icon = '🌮', limit = 100, category = 'food'  },

            -- [ DESSERTS ]
            { item = 'hab_choc', label = 'Dubai Chocolate Rice Pudding', price = 9,  icon = '🍮', limit = 100, category = 'food'  },
            { item = 'hab_tof',  label = 'Baklava Ice Cream Sundae',     price = 10, icon = '🍨', limit = 100, category = 'food'  },

            -- [ DRINKS ]
            { item = 'hab_ach',  label = 'Arabic Coffee Horchata',   price = 7,  icon = '☕', limit = 100, category = 'drink' },
            { item = 'hab_rose', label = 'Rose Water Agua Fresca',   price = 6,  icon = '🌹', limit = 100, category = 'drink' },
        },

        storages = {
            {
                label     = 'Microwave Storage',
                coords    = vector3(17.864103, -1599.101, 29.473117), -- TODO: update with actual coords
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 0.0,
                slots     = 200,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Microwave Storage',
                coords    = vector3(19.130907, -1600.727, 29.293998), -- TODO: update with actual coords
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 0.0,
                slots     = 200,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate',
                coords    = vector3(14.523897, -1600.208, 29.428941), -- TODO: update with actual coords
                size      = vector3(0.5, 0.6, 1.0),
                heading   = 0.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Tray',
                coords    = vector3(16.778263, -1602.417, 29.447389), -- TODO: update with actual coords
                size      = vector3(0.5, 2.4, 1.0),
                heading   = 0.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },

    pearls = {
        label = "Pearl's Seafood",

        blip = {
            sprite = 356,
            colour = 3,
        },

        tills = {
            {
                registerZone = {
                    coords  = vector3(-1835.293, -1185.852, 14.541279), -- TODO: update with actual coords
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 0.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,
                    coords = vector4(-1834.895, -1185.167, 14.457138, 92.451614), -- TODO: update with actual coords
                },
            },

            {
                registerZone = {
                    coords  = vector3(-1836.336, -1189.404, 14.541193), -- TODO: update with actual coords
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 0.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,
                    coords = vector4(-1836.338, -1190.045, 14.457138, 90.831092), -- TODO: update with actual coords
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,
                coords = vector4(-1834.852, -1184.774, 14.457137, 65.870689), -- TODO: update with actual coords
            },
            {
                model  = `prop_drinkmenu`,
                coords = vector4(-1836.311, -1190.441, 14.457138, 122.38307), -- TODO: update with actual coords
            },
        },

        products = {
            -- [ FOOD ]
            { item = 'p_cal',     label = 'Calamari',            price = 16, icon = '🦑', limit = 100, category = 'food'  },
            { item = 'p_fillet',  label = 'Fish Fillet',         price = 18, icon = '🐟', limit = 100, category = 'food'  },
            { item = 'p_boil',    label = 'Seafood Boil',        price = 22, icon = '🦞', limit = 100, category = 'food'  },
            { item = 'p_lobster', label = 'Lobster Tail',        price = 28, icon = '🦞', limit = 100, category = 'food'  },

            -- [ DESSERTS ]
            { item = 'p_crem',    label = 'Crème brûlée',        price = 12, icon = '🍮', limit = 100, category = 'food'  },
            { item = 'p_tai',     label = 'Taiyaki',             price = 8,  icon = '🍡', limit = 100, category = 'food'  },

            -- [ DRINKS ]
            { item = 'p_coco',    label = 'Coconut Water',       price = 5,  icon = '🥥', limit = 100, category = 'drink' },
            { item = 'p_straw',   label = 'Strawberry Lemonade', price = 6,  icon = '🍓', limit = 100, category = 'drink' },
            { item = 'p_shark',   label = 'Shark Attack Shake',  price = 7,  icon = '🦈', limit = 100, category = 'drink' },

            -- [ COCKTAILS ]
            { item = 'p_sex',     label = 'Sex on the Beach',    price = 10, icon = '🍹', limit = 100, category = 'drink' },
            { item = 'p_pina',    label = 'Piña Colada',         price = 10, icon = '🍹', limit = 100, category = 'drink' },
        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(-1838.497, -1191.128, 14.616438), -- TODO: update with actual coords
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 0.0,
                slots     = 200,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Fridge Storage 2',
                coords    = vector3(-1840.956, -1182.507, 14.656069), -- TODO: update with actual coords
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 0.0,
                slots     = 200,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate',
                coords    = vector3(-1841.321, -1188.864, 14.584199), -- TODO: update with actual coords
                size      = vector3(0.5, 0.6, 1.0),
                heading   = 0.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Tray',
                coords    = vector3(-1835.697, -1188.41, 14.457138), -- TODO: update with actual coords
                size      = vector3(0.5, 2.4, 1.0),
                heading   = 0.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
            {
                label     = 'Tray',
                coords    = vector3(-1835.235, -1187.048, 14.457138), -- TODO: update with actual coords
                size      = vector3(0.5, 2.4, 1.0),
                heading   = 0.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },

    hornys = {
        label = 'Hornys',

        blip = {
            sprite = 52,
            colour = 1,
        },

        tills = {
            {
                registerZone = {
                    coords  = vector3(1853.9031, 3779.7368, 33.393413), -- TODO: update with actual coords
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 0.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,
                    coords = vector4(1853.3536, 3780.1848, 33.23487, 301.84808), -- TODO: update with actual coords
                },
            },
            {
                registerZone = {
                    coords  = vector3(1851.8963, 3783.2768, 33.415843), -- TODO: update with actual coords
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 0.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,
                    coords = vector4(1851.9285, 3782.6506, 33.23487, 323.99578), -- TODO: update with actual coords
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,
                coords = vector4(1853.1025, 3780.6025, 33.23487, 302.03359), -- TODO: update with actual coords
            },
            {
                model  = `prop_drinkmenu`,
                coords = vector4(1851.3854, 3783.6459, 33.23487, 342.5346), -- TODO: update with actual coords
            },
        },

        products = {
            -- [ FOOD ]
            { item = 'h_slider', label = 'Sneaky Link Sliders',          price = 10, icon = '🍔', limit = 100, category = 'food'  },
            { item = 'h_shrimp', label = 'Situationship Shrimp Basket',  price = 12, icon = '🍤', limit = 100, category = 'food'  },
            { item = 'h_tots',   label = 'Dirty Little Tots',            price = 7,  icon = '🍟', limit = 100, category = 'food'  },
            { item = 'h_rings',  label = 'Horny Rings',                  price = 6,  icon = '🧅', limit = 100, category = 'food'  },

            -- [ DESSERTS ]
            { item = 'h_sun',    label = 'Forbidden Sundae',             price = 8,  icon = '🍨', limit = 100, category = 'food'  },
            { item = 'h_brownie',label = 'Sticky Situation Brownie',     price = 6,  icon = '🍫', limit = 100, category = 'food'  },

            -- [ DRINKS ]
            { item = 'h_slush',  label = 'Sloppy Slush',                price = 5,  icon = '🧃', limit = 100, category = 'drink' },
            { item = 'h_berry',  label = 'Berry Obsessed Shake',        price = 6,  icon = '🍓', limit = 100, category = 'drink' },
        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(1855.7844, 3785.5961, 33.373603), -- TODO: update with actual coords
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 0.0,
                slots     = 200,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Fridge Storage 2',
                coords    = vector3(1855.4445, 3790.3432, 33.581058), -- TODO: update with actual coords
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 0.0,
                slots     = 200,
                weight    = 400000,
                staffOnly = true,
            },
            {
                label     = 'Hot Plate',
                coords    = vector3(1856.906, 3782.3935, 33.49411), -- TODO: update with actual coords
                size      = vector3(0.5, 0.6, 1.0),
                heading   = 0.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Tray',
                coords    = vector3(1852.3604, 3782.0029, 33.260997), -- TODO: update with actual coords
                size      = vector3(0.5, 2.4, 1.0),
                heading   = 0.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
            {
                label     = 'Tray',
                coords    = vector3(1852.873, 3781.2119, 33.260997), -- TODO: update with actual coords
                size      = vector3(0.5, 2.4, 1.0),
                heading   = 0.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },

    ------------------------ MECHANICS

    stroke = {
        label       = 'Strokemasters',
        serviceOnly = true,  -- bundles are services only, no inventory items required

        -- Items used purely for bundle icon images (from ox_inventory)
        iconItems = {
            { item = 'repair_part_electronics',  label = 'Electronics'          },
            { item = 'repair_part_axle',         label = 'Axle'                 },
            { item = 'repair_part_brakes',       label = 'Brakes'               },
            { item = 'repair_part_clutch',       label = 'Clutch'               },
            { item = 'repair_part_transmission', label = 'Transmission'         },
            { item = 'repair_part_injectors',    label = 'Fuel Injectors'       },
            { item = 'repair_part_rad',          label = 'Radiator'             },
            { item = 'upgrade_engine1',          label = 'Engine Upgrade'       },
            { item = 'upgrade_transmission1',    label = 'Transmission Upgrade' },
            { item = 'upgrade_brakes1',          label = 'Brake Upgrade'        },
            { item = 'upgrade_suspension1',      label = 'Suspension Upgrade'   },
            { item = 'upgrade_turbo',            label = 'Turbo Kit'            },
            { item = 'repairkitadv',             label = 'Adv. Repair Kit'      },
        },

        -- blip = {
        --     sprite = 439,
        --     colour = 5,
        -- },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(-1631.357, -823.686, 9.9673824),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1632.652, -822.5931, 9.9270591, 154.58692),
                },
            },
            {
                registerZone = {
                    coords  = vector3(-1603.131, -837.6741, 10.166143),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(-1603.272, -837.2995, 10.43025, 221.3381),
                },
            },
        },

        menuProps = { 
        },

        products = {
        },

        storages = {
            {
                label     = 'Storage Unit',
                coords    = vector3(-1618.839, -831.9798, 10.236073), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker',
                coords    = vector3(-1617.06, -835.5199, 10.169677), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker',
                coords    = vector3(-1633.557, -820.395, 10.032897), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
        },
    },

    tuner = {
        label       = 'Tunershop',
        serviceOnly = true,  -- bundles are services only, no inventory items required

        -- Items used purely for bundle icon images (from ox_inventory)
        iconItems = {
            { item = 'repair_part_electronics',  label = 'Electronics'          },
            { item = 'repair_part_axle',         label = 'Axle'                 },
            { item = 'repair_part_brakes',       label = 'Brakes'               },
            { item = 'repair_part_clutch',       label = 'Clutch'               },
            { item = 'repair_part_transmission', label = 'Transmission'         },
            { item = 'repair_part_injectors',    label = 'Fuel Injectors'       },
            { item = 'repair_part_rad',          label = 'Radiator'             },
            { item = 'upgrade_engine1',          label = 'Engine Upgrade'       },
            { item = 'upgrade_transmission1',    label = 'Transmission Upgrade' },
            { item = 'upgrade_brakes1',          label = 'Brake Upgrade'        },
            { item = 'upgrade_suspension1',      label = 'Suspension Upgrade'   },
            { item = 'upgrade_turbo',            label = 'Turbo Kit'            },
            { item = 'repairkitadv',             label = 'Adv. Repair Kit'      },
        },

        -- blip = {
        --     sprite = 439,
        --     colour = 5,
        -- },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(744.36352, -1280.142, 26.259086),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(743.09185, -1280.091, 26.155599, 192.4432),
                },
            },
            {
                registerZone = {
                    coords  = vector3(738.03143, -1295.793, 26.179313),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(737.24591, -1295.577, 26.155599, 166.11956),
                },
            },
        },

        menuProps = { 
        },

        products = {
        },

        storages = {
            {
                label     = 'Storage Unit Tuner',
                coords    = vector3(759.07983, -1272.963, 26.557632), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker Tuner',
                coords    = vector3(738.02819, -1289.71, 26.342823), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker Tuner 2',
                coords    = vector3(755.29296, -1280.819, 26.267049), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
        },
    },

    bennys = {
        label       = 'Bennys Mechanics',
        serviceOnly = true,  -- bundles are services only, no inventory items required

        -- Items used purely for bundle icon images (from ox_inventory)
        iconItems = {
            { item = 'repair_part_electronics',  label = 'Electronics'          },
            { item = 'repair_part_axle',         label = 'Axle'                 },
            { item = 'repair_part_brakes',       label = 'Brakes'               },
            { item = 'repair_part_clutch',       label = 'Clutch'               },
            { item = 'repair_part_transmission', label = 'Transmission'         },
            { item = 'repair_part_injectors',    label = 'Fuel Injectors'       },
            { item = 'repair_part_rad',          label = 'Radiator'             },
            { item = 'upgrade_engine1',          label = 'Engine Upgrade'       },
            { item = 'upgrade_transmission1',    label = 'Transmission Upgrade' },
            { item = 'upgrade_brakes1',          label = 'Brake Upgrade'        },
            { item = 'upgrade_suspension1',      label = 'Suspension Upgrade'   },
            { item = 'upgrade_turbo',            label = 'Turbo Kit'            },
            { item = 'repairkitadv',             label = 'Adv. Repair Kit'      },
        },

        -- blip = {
        --     sprite = 439,
        --     colour = 5,
        -- },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(148.91476, -3019.401, 6.9237918),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(149.12823, -3020.492, 6.9237918, 105.79645),
                },
            },
            {
                registerZone = {
                    coords  = vector3(125.40383, -3027.541, 7.1111683),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(127.87097, -3027.608, 7.1420307, 4.6971087),
                },
            },
        },

        menuProps = { 
        },

        products = {
        },

        storages = {
            {
                label     = 'Storage Unit Bennys',
                coords    = vector3(124.1744, -3050.281, 7.18365), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker Bennys',
                coords    = vector3(132.44972, -3016.852, 7.3948302), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker Bennys 2',
                coords    = vector3(127.55603, -3034.601, 7.1420307), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
        },
    },

    seaton = {
        label       = 'Seaton Sands Mechanics',
        serviceOnly = true, 

        iconItems = {
            { item = 'repair_part_electronics',  label = 'Electronics'          },
            { item = 'repair_part_axle',         label = 'Axle'                 },
            { item = 'repair_part_brakes',       label = 'Brakes'               },
            { item = 'repair_part_clutch',       label = 'Clutch'               },
            { item = 'repair_part_transmission', label = 'Transmission'         },
            { item = 'repair_part_injectors',    label = 'Fuel Injectors'       },
            { item = 'repair_part_rad',          label = 'Radiator'             },
            { item = 'upgrade_engine1',          label = 'Engine Upgrade'       },
            { item = 'upgrade_transmission1',    label = 'Transmission Upgrade' },
            { item = 'upgrade_brakes1',          label = 'Brake Upgrade'        },
            { item = 'upgrade_suspension1',      label = 'Suspension Upgrade'   },
            { item = 'upgrade_turbo',            label = 'Turbo Kit'            },
            { item = 'repairkitadv',             label = 'Adv. Repair Kit'      },
        },

        -- blip = {
        --     sprite = 439,
        --     colour = 5,
        -- },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(1696.1201, 3697.2712, 34.419033),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(1696.6953, 3696.1418, 34.419033, 128.82498),
                },
            },
            {
                registerZone = {
                    coords  = vector3(1715.3353, 3683.3452, 34.824882),
                    size    = vector3(0.3, 0.5, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(1714.4865, 3682.7583, 34.824882, 38.915786),
                },
            },
        },

        menuProps = { 
        },

        products = {
        },

        storages = {
            {
                label     = 'Storage Unit Seaton',
                coords    = vector3(1703.0489, 3685.4584, 34.614238), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker Seaton',
                coords    = vector3(1701.955, 3688.143, 34.841678), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
            {
                label     = 'Storage Unit Locker Seaton 2',
                coords    = vector3(1699.1715, 3692.3686, 34.614852), -- update in-game
                size      = vector3(1.0, 0.3, 1.7),
                heading   = 70.0,
                slots     = 400,
                weight    = 3000000,
                staffOnly = true,
            },
        },
    },
    --------------------- NIGHTCLUBS
    hornbills = {
        label = 'Hornbills',
        serviceOnly = true,

        iconItems = {
            { item = 'cranberryvodka',  label = 'cranberryvodka'          },
            { item = 'strawberrydaquiri',         label = 'strawberrydaquiri'                 },
            { item = 'champagne',       label = 'champagne'               },
            { item = 'chickentenders',       label = 'chickentenders'               },
            { item = 'friedpickles', label = 'friedpickles'         },
            { item = 'coconutshrimp',    label = 'coconutshrimp'       },

        },

        blip = {
            sprite = 121, 
            colour = 50, 
        },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(1109.5812, -271.291, 61.89421),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(1108.9592, -271.4724, 61.778244, 5.3313245),
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(1108.2133, -270.5491, 61.784008, 121.42784),
            },
            
        },

        products = {

        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(1107.3762, -266.94, 61.354961), -- update in-game
                size      = vector3(1.2, 0.6, 1.7),
                heading   = 70.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Fridge New',
                coords    = vector3(1108.7412, -267.8538, 61.350914), -- update in-game
                size      = vector3(0.8, 0.4, 1.3),
                heading   = 70.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },

            {
                label     = 'Tray',
                coords    = vector3(1106.95, -269.85, 62.0), -- update in-game
                size      = vector3(1.0, 0.85, 0.5),
                heading   = 70.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },

    mooreclub = {
        label = 'Mooreclub',
        serviceOnly = true,

        iconItems = {
            { item = 'longislandicedtea',  label = 'longislandicedtea'          },
            { item = 'bluehawaiian',         label = 'bluehawaiian'                 },
            { item = 'moscowmule',       label = 'moscowmule'               },
            { item = 'nachos',       label = 'nachos'               },
            { item = 'chipsandqueso', label = 'chipsandqueso'         },
            { item = 'hotwings',    label = 'hotwings'       },

        },

        blip = {
            sprite = 121, 
            colour = 1, 
        },

        tills = {
            -- Till 1
            {
                registerZone = {
                    coords  = vector3(128.09761, -1282.643, 29.536457),
                    size    = vector3(0.3, 0.3, 0.3),
                    heading = 70.0,
                },
                payTerminalProp = {
                    model  = `p_till_01_s`,  -- replace with your prop model
                    coords = vector4(128.30197, -1284.299, 29.29515, 318.64657),
                },
            },
        },

        menuProps = {
            {
                model  = `prop_drinkmenu`,  -- replace with your menu board prop model
                coords = vector4(128.7489, -1284.956, 29.29515, 305.51486),
            },
            
        },

        products = {

        },

        storages = {
            {
                label     = 'Fridge Storage',
                coords    = vector3(129.97245, -1281.431, 28.913925), -- update in-game
                size      = vector3(1.2, 0.6, 1.7),
                heading   = 70.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },
            {
                label     = 'Fridge New',
                coords    = vector3(131.98658, -1284.905, 28.742492), -- update in-game
                size      = vector3(0.8, 0.4, 1.3),
                heading   = 70.0,
                slots     = 50,
                weight    = 100000,
                staffOnly = true,
            },

            {
                label     = 'Tray',
                coords    = vector3(126.96522, -1282.448, 29.521928), -- update in-game
                size      = vector3(1.5, 1.5, 1.5),
                heading   = 70.0,
                slots     = 10,
                weight    = 50000,
                staffOnly = false,
            },
        },
    },
}
