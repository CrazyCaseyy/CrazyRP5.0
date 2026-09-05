return {
    checkInCost = 2000, -- Price for using the hospital check-in system
    minForCheckIn = 2, -- Minimum number of people with the ambulance job to prevent the check-in system from being used

    locations = { -- Various interaction points
        duty = {
            vec3(90.7, -412.09, 39.59),
            vec3(-254.88, 6324.5, 32.58),
        },
        vehicle = {
            vec4(80.47, -430.88, 38.38, 70.83),
            vec4(-234.28, 6329.16, 32.15, 222.5),
        },
        helicopter = {
            vec4(94.96, -421.48, 85.3, 65.99),
            vec4(-475.43, 5988.353, 31.716, 31.34),
        },
        armory = {
            {
                shopType = 'AmbulanceArmory',
                name = 'Armory',
                groups = { ambulance = 0 },
                inventory = {
                    { name = 'radio', price = 0 },
                    { name = 'bandage', price = 0 },
                    { name = 'painkillers', price = 0 },
                    { name = 'firstaid', price = 0 },
                    -- Was missing despite server/main.lua already registering
                    -- a CreateUseableItem handler for it (hospital:client:UseIfaks) -
                    -- nowhere to actually get one before this.
                    { name = 'ifaks', price = 0 },
                    { name = 'armour', price = 0 },
                    { name = 'weapon_flashlight', price = 0 },
                    { name = 'weapon_fireextinguisher', price = 0 },
                },
                locations = {
                    vec3(112.29, -372.6, 39.52)
                }
            }
        },
        -- Not given a new coord with the rest of this hospital's move - the
        -- new helicopter spawn is a ground-level garage (see `helicopter`
        -- above), not a rooftop, so this may no longer apply. Left pointing
        -- at the old Pillbox roof access until confirmed either way.
        roof = {
            vec3(338.54, -583.88, 74.17),
        },
        main = {
            vec3(88.33, -413.32, 39.53),
        },
        stash = {
            {
                name = 'ambulanceStash',
                label = 'Personal stash',
                weight = 100000,
                slots = 30,
                groups = { ambulance = 0 },
                owner = true, -- Set to false for group stash
                location = vec3(87.25, -428.1, 39.75)
            }
        },

        ---@class Bed
        ---@field coords vector4
        ---@field model number

        ---@type table<string, {coords: vector3, checkIn?: vector3|vector3[], beds: Bed[]}>
        hospitals = {
            pillbox = {
                -- TODO: model hashes below are placeholders reused from the old
                -- vanilla street beds (GetClosestObjectOfType only uses this to
                -- freeze the underlying bed prop so it doesn't shift under the
                -- player - low severity if wrong, but should be swapped for
                -- whatever prop actually sits at each new bed coord).
                coords = vec3(88.33, -413.32, 39.53),
                checkIn = vec3(88.33, -413.32, 39.53),
                beds = {
                    {coords = vec4(100.5, -407.42, 39.25, 337.82), model = 1631638868},
                    {coords = vec4(104.31, -408.68, 39.25, 339.21), model = 1631638868},
                    {coords = vec4(105.72, -403.07, 39.25, 80.67), model = 2117668672},
                    {coords = vec4(106.92, -399.68, 39.25, 66.69), model = 2117668672},
                    {coords = vec4(108.08, -396.43, 39.25, 71.56), model = 2117668672},
                    {coords = vec4(110.34, -392.43, 39.25, 164.63), model = -1091386327},
                    {coords = vec4(106.38, -391.04, 39.25, 160.28), model = -1091386327},
                },
            },
            paleto = {
                coords = vec3(-250, 6315, 32),
                checkIn = vec3(-254.54, 6331.78, 32.43),
                beds = {
                    {coords = vec4(-252.43, 6312.25, 32.34, 313.48), model = 2117668672},
                    {coords = vec4(-247.04, 6317.95, 32.34, 134.64), model = 2117668672},
                    {coords = vec4(-255.98, 6315.67, 32.34, 313.91), model = 2117668672},
                },
            },
            jail = {
                coords = vec3(1761, 2600, 46),
                beds = {
                    {coords = vec4(1761.96, 2597.74, 45.66, 270.14), model = 2117668672},
                    {coords = vec4(1761.96, 2591.51, 45.66, 269.8), model = 2117668672},
                    {coords = vec4(1771.8, 2598.02, 45.66, 89.05), model = 2117668672},
                    {coords = vec4(1771.85, 2591.85, 45.66, 91.51), model = 2117668672},
                },
            },
        },

        stations = {
            {label = 'Pillbox Hospital', coords = vec4(80.47, -430.88, 38.38, 70.83)},
        }
    },
}