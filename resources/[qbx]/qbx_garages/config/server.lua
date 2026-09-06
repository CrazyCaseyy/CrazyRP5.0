---Represents a function that calculates a fee based on vehicle data.
---
---The function receives a vehicle identifier and a model name,
---retrieves or derives the necessary vehicle information,
---and returns a numeric fee based on custom logic.
---
---@alias FeeCalculator fun(vehicleId: number, modelName: string): number

return {
    autoRespawn = false,   -- True == auto respawn cars that are outside into your garage on script restart, false == does not put them into your garage and players have to go to the impound
    warpInVehicle = false, -- If false, player will no longer warp into vehicle upon taking the vehicle out.
    doorsLocked = true, -- If true, the doors will be locked upon taking the vehicle out.
    distanceCheck = 5.0, -- The distance that needs to bee clear to let the vehicle spawn, this prevents vehicles stacking on top of each other
    -- Impound retrieval is free - was `require 'server.default-calculate-impound-fee'`
    -- (2% of the vehicle's price), that file is left in place unused in case
    -- a fee ever needs to come back.
    calculateImpoundFee = function() return 0 end,
    logging = {
        webhook = {
            error = 'https://discord.com/api/webhooks/1539180753471012905/KV82AecVyW1qddorcOnSsJjxincnHC6bgOTX2-qzlPJW25HEIssFO8vVS1cAm_5j7L7L',
            default = 'https://discord.com/api/webhooks/1539180753471012905/KV82AecVyW1qddorcOnSsJjxincnHC6bgOTX2-qzlPJW25HEIssFO8vVS1cAm_5j7L7L',
            anticheat = 'https://discord.com/api/webhooks/1539180753471012905/KV82AecVyW1qddorcOnSsJjxincnHC6bgOTX2-qzlPJW25HEIssFO8vVS1cAm_5j7L7L',
        },
    },

    ---@class GarageBlip
    ---@field name? string -- Name of the blip. Defaults to garage label.
    ---@field sprite? number -- Sprite for the blip. Defaults to 357
    ---@field color? number -- Color for the blip. Defaults to 3.

    ---The place where the player can access the garage and spawn a car
    ---@class AccessPoint
    ---@field coords vector4 where the garage menu can be accessed from
    ---@field blip? GarageBlip
    ---@field spawn? vector4 where the vehicle will spawn. Defaults to coords
    ---@field dropPoint? vector3 where a vehicle can be stored, Defaults to spawn or coords
    ---@field drawRadius? number draw distance for the garage marker (default: 60)
    ---@field dropDrawRadius? number draw distance for the drop-off marker (default: 60)
    ---@field useRadius? number interaction distance for the garage marker (default: 1)
    ---@field dropUseRadius? number interaction distance for the drop-off marker (default: 1.5)

    ---@class GarageConfig
    ---@field label string -- Label for the garage
    ---@field type? GarageType -- Optional special type of garage. Currently only used to mark DEPOT garages.
    ---@field vehicleType VehicleType -- Vehicle type
    ---@field groups? string | string[] | table<string, number> job/gangs that can access the garage
    ---@field shared? boolean defaults to false. Shared garages give all players with access to the garage access to all vehicles in it. If shared is off, the garage will only give access to player's vehicles which they own.
    ---@field states? VehicleState | VehicleState[] if set, only vehicles in the given states will be retrievable from the garage. Defaults to GARAGED.
    ---@field skipGarageCheck? boolean if true, returns vehicles for retrieval regardless of if that vehicle's garage matches this garage's name
    ---@field canAccess? fun(source: number): boolean checks access as an additional guard clause. Other filter fields still need to pass in addition to this function.
    ---@field accessPoints AccessPoint[]

    ---@type table<string, GarageConfig>

    garages = {
        -- Public Garages
        -- Bigger interact zones than the ox_lib defaults (useRadius 1 /
        -- dropUseRadius 1.5) - drawRadius (60, unchanged) is just the
        -- outer range at which the real interact zone gets spun up at
        -- all, so it's not what makes these feel small in practice.
        -- Only the first access point per garage carries a blip, so
        -- multi-spot garages show one map marker, not one per spot.
        whitegarage = {
            label = 'White Garage Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(-461.03, -816.73, 29.58, 268.7),
                    spawn = vec4(-461.03, -816.73, 29.58, 268.7),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-460.6, -813.38, 29.56, 278.06),
                    spawn = vec4(-460.6, -813.38, 29.56, 278.06),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-460.99, -809.95, 29.54, 266.29),
                    spawn = vec4(-460.99, -809.95, 29.54, 266.29),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        redgarage = {
            label = 'Red Garage Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(-356.61, -775.97, 32.97, 266.07),
                    spawn = vec4(-356.61, -775.97, 32.97, 266.07),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-357.53, -771.06, 32.97, 266.99),
                    spawn = vec4(-357.53, -771.06, 32.97, 266.99),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-357.39, -767.86, 32.97, 266.82),
                    spawn = vec4(-357.39, -767.86, 32.97, 266.82),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        motormotel68 = {
            label = 'Motor Motel Route 68 Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(1131.6, 2646.24, 37.0, 358.64),
                    spawn = vec4(1131.6, 2646.24, 37.0, 358.64),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(1127.77, 2646.71, 37.0, 359.08),
                    spawn = vec4(1127.77, 2646.71, 37.0, 359.08),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(1124.19, 2646.21, 37.0, 356.44),
                    spawn = vec4(1124.19, 2646.21, 37.0, 356.44),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        legionparking = {
            label = 'Legion Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(216.18, -804.59, 29.8, 71.95),
                    spawn = vec4(216.18, -804.59, 29.8, 71.95),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(205.53, -800.88, 30.02, 248.56),
                    spawn = vec4(205.53, -800.88, 30.02, 248.56),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(206.46, -798.37, 30.0, 252.07),
                    spawn = vec4(206.46, -798.37, 30.0, 252.07),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(216.67, -801.91, 29.79, 68.94),
                    spawn = vec4(216.67, -801.91, 29.79, 68.94),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        clintonave = {
            label = 'Clinton Avenue Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(375.2, 295.34, 102.28, 162.65),
                    spawn = vec4(375.2, 295.34, 102.28, 162.65),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(378.92, 293.95, 102.2, 168.11),
                    spawn = vec4(378.92, 293.95, 102.2, 168.11),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(360.71, 293.87, 102.52, 251.69),
                    spawn = vec4(360.71, 293.87, 102.52, 251.69),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(359.19, 290.26, 102.51, 253.03),
                    spawn = vec4(359.19, 290.26, 102.51, 253.03),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        -- Only 2 spots - the 3rd, 4th coords given for this one were an
        -- exact duplicate of the 1st (same vec4 repeated 3 times), so that
        -- access point isn't repeated 3 times over here. Worth
        -- double-checking those were meant to be distinct spots.
        autopiaparkway = {
            label = 'Autopia Parkway Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(-776.3, -2024.65, 7.87, 216.84),
                    spawn = vec4(-776.3, -2024.65, 7.87, 216.84),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-767.91, -2017.74, 7.88, 228.29),
                    spawn = vec4(-767.91, -2017.74, 7.88, 228.29),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        paletoblvd = {
            label = 'Paleto Blvd Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(73.08, 6404.79, 30.23, 134.83),
                    spawn = vec4(73.08, 6404.79, 30.23, 134.83),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(75.92, 6402.02, 30.23, 134.79),
                    spawn = vec4(75.92, 6402.02, 30.23, 134.79),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(78.76, 6399.21, 30.23, 136.88),
                    spawn = vec4(78.76, 6399.21, 30.23, 136.88),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(81.2, 6396.37, 30.23, 132.07),
                    spawn = vec4(81.2, 6396.37, 30.23, 132.07),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        gomastreet = {
            label = 'Goma Street Parking',
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Public Parking', sprite = 357, color = 3 },
                    coords = vec4(-1182.86, -1495.46, 3.38, 129.24),
                    spawn = vec4(-1182.86, -1495.46, 3.38, 129.24),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-1191.24, -1504.36, 3.37, 304.35),
                    spawn = vec4(-1191.24, -1504.36, 3.37, 304.35),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-1184.35, -1492.73, 3.38, 123.99),
                    spawn = vec4(-1184.35, -1492.73, 3.38, 123.99),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
                {
                    coords = vec4(-1186.23, -1490.29, 3.38, 125.64),
                    spawn = vec4(-1186.23, -1490.29, 3.38, 125.64),
                    useRadius = 3.0,
                    dropUseRadius = 3.0,
                },
            },
        },
        intairport = {
            label = 'Airport Hangar',
            vehicleType = VehicleType.AIR,
            accessPoints = {
                {
                    blip = {
                        name = 'Hangar',
                        sprite = 360,
                        color = 3,
                    },
                    coords = vec4(-1025.34, -3017.0, 13.95, 331.99),
                    spawn = vec4(-979.2, -2995.51, 13.95, 52.19),
                    useRadius = 2.0,
                    dropUseRadius = 4.0,
                    drawRadius = 100,
                    dropDrawRadius = 250,
                }
            },
        },
        higginsheli = {
            label = 'Higgins Helitours',
            vehicleType = VehicleType.AIR,
            accessPoints = {
                {
                    blip = {
                        name = 'Hangar',
                        sprite = 360,
                        color = 3,
                    },
                    coords = vec4(-722.12, -1472.74, 5.0, 140.0),
                    spawn = vec4(-724.83, -1443.89, 5.0, 140.0),
                    useRadius = 2.0,
                    dropUseRadius = 4.0,
                    drawRadius = 100,
                    dropDrawRadius = 250,
                }
            },
        },
        airsshores = {
            label = 'Sandy Shores Hangar',
            vehicleType = VehicleType.AIR,
            accessPoints = {
                {
                    blip = {
                        name = 'Hangar',
                        sprite = 360,
                        color = 3,
                    },
                    coords = vec4(1757.74, 3296.13, 41.15, 142.6),
                    spawn = vec4(1740.88, 3278.99, 41.09, 189.46),
                    useRadius = 2.0,
                    dropUseRadius = 4.0,
                    drawRadius = 100,
                    dropDrawRadius = 250,
                }
            },
        },
        lsymc = {
            label = 'LSYMC Boathouse',
            vehicleType = VehicleType.SEA,
            accessPoints = {
                {
                    blip = {
                        name = 'Boathouse',
                        sprite = 356,
                        color = 3,
                    },
                    coords = vec4(-794.64, -1510.89, 1.6, 201.55),
                    spawn = vec4(-793.58, -1501.4, 0.12, 111.5),
                    dropUseRadius = 3.0,
                    dropDrawRadius = 100,
                }
            },
        },
        paleto = {
            label = 'Paleto Boathouse',
            vehicleType = VehicleType.SEA,
            accessPoints = {
                {
                    blip = {
                        name = 'Boathouse',
                        sprite = 356,
                        color = 3,
                    },
                    coords = vec4(-277.4, 6637.01, 7.5, 40.51),
                    spawn = vec4(-289.2, 6637.96, 1.01, 45.5),
                    dropUseRadius = 3.0,
                    dropDrawRadius = 100,
                }
            },
        },
        millars = {
            label = 'Millars Boathouse',
            vehicleType = VehicleType.SEA,
            accessPoints = {
                {
                    blip = {
                        name = 'Boathouse',
                        sprite = 356,
                        color = 3,
                    },
                    coords = vec4(1299.02, 4216.42, 33.91, 166.8),
                    spawn = vec4(1296.78, 4203.76, 30.12, 169.03),
                    dropUseRadius = 3.0,
                    dropDrawRadius = 100,
                }
            },
        },

        -- Job Garages
        police = {
            label = 'Police',
            vehicleType = VehicleType.CAR,
            groups = 'police',
            accessPoints = {
                {
                    coords = vec4(454.6, -1017.4, 28.4, 0),
                    spawn = vec4(438.4, -1018.3, 27.7, 90.0),
                }
            },
        },

        -- Gang Garages
        ballas = {
            label = 'Ballas',
            vehicleType = VehicleType.CAR,
            groups = 'ballas',
            accessPoints = {
                {
                    coords = vec4(98.50, -1954.49, 20.84, 0),
                    spawn = vec4(98.50, -1954.49, 20.75, 335.73),
                }
            },
        },
        families = {
            label = 'La Familia',
            vehicleType = VehicleType.CAR,
            groups = 'families',
            accessPoints = {
                {
                    coords = vec4(-811.65, 187.49, 72.48, 0),
                    spawn = vec4(-818.43, 184.97, 72.28, 107.85),
                }
            },
        },
        lostmc = {
            label = 'Lost MC',
            vehicleType = VehicleType.CAR,
            groups = 'lostmc',
            accessPoints = {
                {
                    coords = vec4(957.25, -129.63, 74.39, 0),
                    spawn = vec4(957.25, -129.63, 74.39, 199.21),
                }
            },
        },
        cartel = {
            label = 'Cartel',
            vehicleType = VehicleType.CAR,
            groups = 'cartel',
            accessPoints = {
                {
                    coords = vec4(1407.18, 1118.04, 114.84, 0),
                    spawn = vec4(1407.18, 1118.04, 114.84, 88.34),
                }
            },
        },

        -- Impound Lots
        impoundlot = {
            label = 'Impound Lot',
            type = GarageType.DEPOT,
            states = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = {
                        name = 'Impound Lot',
                        sprite = 68,
                        color = 3,
                    },
                    coords = vec4(400.45, -1630.87, 29.29, 228.88),
                    spawn = vec4(407.2, -1645.58, 29.31, 228.28),
                }
            },
        },
        airdepot = {
            label = 'Air Depot',
            type = GarageType.DEPOT,
            states = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            vehicleType = VehicleType.AIR,
            accessPoints = {
                {
                    blip = {
                        name = 'Air Depot',
                        sprite = 359,
                        color = 3,
                    },
                    coords = vec4(-1244.35, -3391.39, 13.94, 59.26),
                    spawn = vec4(-1269.03, -3376.7, 13.94, 330.32),
                }
            },
        },
        seadepot = {
            label = 'LSYMC Depot',
            type = GarageType.DEPOT,
            states = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            vehicleType = VehicleType.SEA,
            accessPoints = {
                {
                    blip = {
                        name = 'LSYMC Depot',
                        sprite = 356,
                        color = 3,
                    },
                    coords = vec4(-772.71, -1431.11, 1.6, 48.03),
                    spawn = vec4(-729.77, -1355.49, 1.19, 142.5),
                }
            },
        },
    },
}