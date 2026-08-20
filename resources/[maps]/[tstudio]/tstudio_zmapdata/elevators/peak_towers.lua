return {
    resourceName = "tstudio_peak_towers_zdlc_lobbys",
    
    locales = {
        ["en"] = {
            ["menu-title"] = "Peak Towers",
            ["menu-description"] = "Peak Towers Elevator",
            ["floor-description"] = "Teleport to %s",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Open Elevator",
            -- Car elevator locale
            ["car-menu-title"] = "Car Elevator",
            ["car-menu-description"] = "Peak Towers Vehicle Transport",
            ["car-floor-description"] = "Drive to %s",
            ["car-help-notify"] = "~INPUT_CONTEXT~ Use Car Elevator",
            ["car-help-return"] = "~INPUT_CONTEXT~ Return",
            ["car-no-vehicle"] = "You need a vehicle to use this elevator"
        },
        ["de"] = {
            ["menu-title"] = "Peak Towers",
            ["menu-description"] = "Peak Towers Aufzug",
            ["floor-description"] = "Auf %s teleportieren",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Aufzug öffnen",
            -- Car elevator locale
            ["car-menu-title"] = "Autoaufzug",
            ["car-menu-description"] = "Peak Towers Fahrzeugtransport",
            ["car-floor-description"] = "Fahren nach %s",
            ["car-help-notify"] = "~INPUT_CONTEXT~ Autoaufzug benutzen",
            ["car-help-return"] = "~INPUT_CONTEXT~ Zurück",
            ["car-no-vehicle"] = "Du brauchst ein Fahrzeug für diesen Aufzug"
        }
    },
    
    marker = {
        type = 2,
        r = 128,
        g = 64,
        b = 0,
        alpha = 50
    },
    
    -- Header gradient colors (top to bottom)
    header = {
        topColor = {r = 128, g = 64, b = 0},      -- Orange top
        bottomColor = {r = 64, g = 32, b = 0}     -- Darker orange bottom
    },
    
    -- Garage - Lobby - 2. Floor - (Apartments) - Rooftop
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(48.909, -943.088, 307.530, 252.043)
                },
                [2] = {
                    name = "Horizon Link",
                    pos = vector4(60.164, -959.619, 210.739, 159.569)
                },
                [3] = {
                    name = "Business Lounge",
                    pos = vector4(20.937, -903.484, 39.849, 271.276)
                },
                [4] = {
                    name = "Reception",
                    pos = vector4(21.964, -907.969, 30.408, 312.862)
                },
                [5] = {
                    name = "Parking Garage",
                    pos = vector4(77.273, -909.112, -71.163, 272.234)
                }
            }
        },
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(153.707, -1078.353, 263.535, 80.651)
                },
                [2] = {
                    name = "Horizon Link",
                    pos = vector4(153.824, -1064.056, 210.746, 314.166)
                },
                [3] = {
                    name = "Reception Tower B",
                    pos = vector4(136.032, -1066.309, 30.582, 4.116)
                }
            }
        }
    },

    -- Car marker: flat cylinder, larger for vehicles
    carMarker = {
        type = 1,
        r = 128,
        g = 64,
        b = 0,
        alpha = 100,
        scaleX = 5.0,
        scaleY = 5.0,
        scaleZ = 0.5
    },

    -- Car Elevators: multiple sources lead to a single destination
    -- Destination returns randomly to one of the sources
    carElevators = {
        {
            destination = {
                name = "Parking Deck",
                pos = vector4(85.586, -898.033, -71.167, 176.223) -- TODO: Replace with actual coordinates
            },
            sources = {
                [1] = {
                    name = "Street Level A",
                    pos = vector4(81.206, -879.657, 27.602, 55.563) -- TODO: Replace with actual coordinates
                },
                [2] = {
                    name = "Street Level B",
                    pos = vector4(70.011, -891.686, 27.602, 50.85) -- TODO: Replace with actual coordinates
                }
            }
        }
    }
}
