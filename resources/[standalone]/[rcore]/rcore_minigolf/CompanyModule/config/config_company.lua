Config = Config or {}

-- Interval for the salary in minutes
Config.SalaryPayoutInterval = 60

Config.CompanyList = {
    ["MinigolfCompany0"] = {
        -- Enable/Disable buying this company? ( Will disable buy markers + boss menu aswell )
        EnableBuyingCompany = false,

        -- Is payout based on time interval?
        -- true  = in X amount of time it will pay X amount of money
        -- false = it wont pay anything never
        IsIntervalPayOutEnabled = true,
        -- Is boss grade allowed to edit salary grade?
        IsSalaryAllowedToEdit = true,
        -- Is money for salary taken from company stock?
        -- true  = The money will be taken from company stock
        -- false = The money will be still sent but it wont take anything from company stock.
        IsMoneySentFromCompanyStock = true,

        -- settings of your blip
        BlipSettings = {
            -- if this is set to false = the blip wont render
            enable = false,

            -- position of the blip?
            pos = vec3(-1351.22, -1227.68, 5),

            -- blip options
            options = {
                -- the blip name on map ( if you left this on false the blip name will be set from "companyName" )
                --name = "Police station",
                name = false,

                -- the blip sprite
                sprite = 475,

                -- type of the blip = https://docs.fivem.net/natives/?_0x9029B2F3DA924928
                type = 4,

                -- scale of the blip on minimap/big map
                scale = 1.0,

                -- blip color = https://docs.fivem.net/docs/game-references/blips/#blip-colors
                color = 0,

                -- Sets whether or not the specified blip should only be displayed when nearby, or on the minimap.
                shortRange = true,
            },
        },

        -- company data
        CompanyData = {
            -- the name of the company ( will be displayed on minimap blip )
            companyName = "Minigolf Professionals",

            -- price of the company
            price = 10000,

            -- maximum employees this company can hire?
            maximumEmployees = 3,

            -- this will not be possible to rewrite after the company will be created, it will have in default that much money
            companyMoneyInStock = 10000,

            -- company variables ( server side only )
			companyVariables = {},
        },

        --
        MarkerList = {
            ------------------------
            bossMarker = {
                -- the vector4 is used for the object rotation the last parameter is used for heading
                position = {
                    -- object position
                    vector4(-1352.52, -1223.96, 5.75, 110.0),

                    -- marker position
                    --vector4(-1352.52, -1223.96, 5.94),
                },

                -- if you're using object for this instead, then increase the distance to 50 at lest!
                distance = 10,

                -- what object will be spawned instead of marker ( best to use for target system )
                spawnObjectInstead = "prop_laptop_01a",

                -- if you set the disableMarker on true it will be spawning the object defined above
                disableMarker = true,

                -- render only if player owns it?
                renderOnlyForOwner = false,

                -- styling of this specific marker.
                style = {
                    size = vector3(1.0, 1.0, 1.0),
                    rotate = true,
                    faceCamera = false,
                    bobUpAndDown = false,
                    color = { r = 255, g = 255, b = 255, a = 100 },
                    type = 31,
                },
            },
            ------------------------
            buyMarker = {
                -- the vector4 is used for the object rotation the last parameter is used for heading
                position = {
                    -- marker with correct height
                    --vector4(432.31, -985.4, 30.71, 180.0),

                    -- object with correct height
                    vector4(-1350.17, -1230.89, 4.95, 110.0)
                },

                -- if you're using object for this instead, then increase the distance to 50 at lest!
                distance = 10,

                -- what object will be spawned instead of marker ( best to use for target system )
                spawnObjectInstead = "rcore_minigolf_salesign",

                -- if you set the disableMarker on true it will be spawning the object defined above
                disableMarker = true,

                -- Menu background? ( works only with our rcore MenuAPI Best resolution is: 455x117 and they're saved in MenuAPI/html/img/ )
                background_image = "none",

                -- render only when for sale?
                renderOnlyWhenForSale = true,

                -- styling of this specific marker.
                style = {
                    size = vector3(1.0, 1.0, 1.0),
                    rotate = true,
                    faceCamera = false,
                    bobUpAndDown = false,
                    color = { r = 0, g = 255, b = 0, a = 100 },
                    type = 29,
                },
            },
            ------------------------
        },
    },
}