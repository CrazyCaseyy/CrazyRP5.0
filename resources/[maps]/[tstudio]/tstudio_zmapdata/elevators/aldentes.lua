return {
    resourceName = "tstudio_aldentes",
    
    locales = {
        ["en"] = {
            ["menu-title"] = "Al Dente's",
            ["menu-description"] = "Al Dente's: Restaurant & Bar",
            ["floor-description"] = "Teleport to %s",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Open Elevator"
        },
        ["de"] = {
            ["menu-title"] = "Al Dente's",
            ["menu-description"] = "Al Dente's: Restaurant & Bar",
            ["floor-description"] = "Auf %s teleportieren",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Aufzug öffnen"
        }
    },
    
    header = {
        topColor = {r = 255, g = 0, b = 0},      -- Red
        bottomColor = {r = 0, g = 128, b = 0}   -- Green
    },
    
    marker = {
        type = 2,
        r = 95,
        g = 173,
        b = 35,
        alpha = 50
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Apartment",
                    pos = vector4(-1193.514, -1398.177, 14.273, 211.087)
                },
                [2] = {
                    name = "Office Space",
                    pos = vector4(-1193.713, -1398.094, 9.912, 215.294)
                },
                [3] = {
                    name = "Restaurant",
                    pos = vector4(-1199.501, -1389.740, 4.584, 296.485)
                },
                [4] = {
                    name = "Basement",
                    pos = vector4(-1199.088, -1391.241, -101.107, 318.631)
                }
            }
        },
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(-1191.882, -1400.193, 17.927, 215.03)
                },
                [2] = {
                    name = "Restaurant",
                    pos = vector4(-1188.616, -1396.170, 4.752, 213.178)
                }
            }
        }
    }
}
