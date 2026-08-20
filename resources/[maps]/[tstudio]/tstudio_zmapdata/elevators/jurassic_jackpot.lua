return {
    resourceName = "tstudio_jurassic_jackpot",
    
    locales = {
        ["en"] = {
            ["menu-title"] = "Jurassic Jackpot",
            ["menu-description"] = "Jurassic Jackpot: Casino & Bar Club",
            ["floor-description"] = "Teleport to %s",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Open Elevator"
        },
        ["de"] = {
            ["menu-title"] = "Jurassic Jackpot",
            ["menu-description"] = "Jurassic Jackpot: Casino & Bar Club",
            ["floor-description"] = "Auf %s teleportieren",
            ["floor-label"] = "➤",
            ["elevator-help-notify"] = "~INPUT_CONTEXT~ Aufzug öffnen"
        }
    },
    
    header = {
        topColor = {r = 0, g = 255, b = 0},      -- Green
        bottomColor = {r = 0, g = 100, b = 0}   -- Darker green
    },
    
    marker = {
        type = 2,
        r = 53,
        g = 154,
        b = 71,
        alpha = 50
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Helipad",
                    pos = vector4(-271.861, -918.529, 52.734, 340.129)
                },
                [2] = {
                    name = "Boss Room",
                    pos = vector4(-269.587, -918.498, 46.297, 338.799)
                },
                [3] = {
                    name = "Casino Main Hall",
                    pos = vector4(-269.574, -918.395, 32.320, 337.101)
                }
            }
        }
    }
}
