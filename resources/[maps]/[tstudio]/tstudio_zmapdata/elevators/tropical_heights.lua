return {
    resourceName = "tstudio_tropical_heights",
    
    locales = {
        ["en"] = {
            ["menu-title"] = "Tropical Heights",
            ["menu-description"] = "Tropical Heights: Bar & Night Club",
            ["floor-description"] = "Teleport to %s",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Open Elevator"
        },
        ["de"] = {
            ["menu-title"] = "Tropical Heights",
            ["menu-description"] = "Tropical Heights: Bar & Night Club",
            ["floor-description"] = "Auf %s teleportieren",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Aufzug öffnen"
        }
    },
    
    header = {
        topColor = {r = 255, g = 192, b = 203},  -- Pink
        bottomColor = {r = 128, g = 0, b = 128} -- Purple
    },
    
    marker = {
        type = 2,
        r = 235,
        g = 52,
        b = 210,
        alpha = 50
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(315.935, -913.750, 57.411, 135.65)
                },
                [2] = {
                    name = "Bar & Night Club",
                    pos = vector4(310.226, -916.654, 52.808, 68.906)
                },
                [3] = {
                    name = "Lobby",
                    pos = vector4(310.696, -916.831, 29.475, 74.755)
                }
            }
        }
    }
}
