Config = {}

-- Debug flag to control console output
Config.Debug = false

-- Global marker settings (from PVG system)
Config.MarkerSettings = {
    type = 2, -- Marker type
    scale = {x = 0.2, y = 0.2, z = 0.2},
    drawDistance = 2.0,
    interactionDistance = 1.0
}

-- UI Blip/marker where players can open the scenario UI
Config.UIBlip = {
    coords = vector3(470.638, -980.273, 21.949),
    sprite = 161,
    color = 3,
    scale = 0.8,
    name = 'MRPD Scenarios',
    -- Use same marker settings as PVG system
    markerType = 2, -- Same as PVG markers
    markerScale = Config.MarkerSettings.scale,
    markerColor = { r = 0, g = 150, b = 255, a = 50 }, -- Blue color to distinguish from PVG
    interactKey = 38, -- E
    interactDist = Config.MarkerSettings.interactionDistance,
    drawDistance = Config.MarkerSettings.drawDistance
}

-- PVG Room Configurations
-- Each room has markers that control different entity sets
Config.Rooms = {
    -- Room 1: Mission Row Police Department - Observation Rooms
    {
        name = "MRPD Observation Room 01",
        ipl = "tstudio_mrpd_garage_milo_",
        roomCoords = vector3(459.153931, -991.876648, 22.57239), -- Center of the room for IPL reference
        markers = {
            {
                id = "obs01_privacy",
                name = "Privacy Controls",
                coords = vector3(462.929, -988.328, 21.949),
                color = {r = 60, g = 82, b = 145, a = 50},
                entitySetsOn = { "observation01_pv_on" },
                entitySetsOff = { "observation01_pv_off" }
            },
            {
                id = "obs01_privacy_window",
                name = "Privacy Window Controls",
                coords = vector3(462.880, -990.704, 21.949),
                color = {r = 60, g = 82, b = 145, a = 50},
                entitySetsOn = { "observation01_pvwindow_on" },
                entitySetsOff = { "observation01_pvwindow_off" }
            },
            {
                id = "obs02_privacy",
                name = "Privacy Controls",
                coords = vector3(462.953, -998.502, 21.949),
                color = {r = 60, g = 82, b = 145, a = 50},
                entitySetsOn = { "observation02_pv_on" },
                entitySetsOff = { "observation02_pv_off" }
            },
            {
                id = "obs02_privacy_window",
                name = "Privacy Window Controls",
                coords = vector3(462.906, -996.185, 21.949),
                color = {r = 60, g = 82, b = 145, a = 50},
                entitySetsOn = { "observation02_pvwindow_on" },
                entitySetsOff = { "observation02_pvwindow_off" }
            },
            {
                id = "obs03_privacy",
                name = "Privacy Controls",
                coords = vector3(479.081, -998.533, 21.949),
                color = {r = 60, g = 82, b = 145, a = 50},
                entitySetsOn = { "observation03_pv_on" },
                entitySetsOff = { "observation03_pv_off" }
            },
            {
                id = "obs03_privacy_window",
                name = "Privacy Window Controls",
                coords = vector3(479.070, -996.262, 21.970),
                color = {r = 60, g = 82, b = 145, a = 50},
                entitySetsOn = { "observation03_pvwindow_on" },
                entitySetsOff = { "observation03_pvwindow_off" }
            },
        }
    },
}

-- Cards configuration with entitysets
Config.Cards = {
    {
        id = 'scenario-01',
        title = 'SAFE\nHOUSE',
        description = 'Secure and clear a safe house location for witness protection operations.',
        duration = 20,
        durationUnit = 'Minutes',
        showDuration = false,
        image = './1.jpg',
        interior = 'tstudio_mrpd_int_garage', -- Replace with actual interior name/hash
        entitysets = { 'scenario_set01' }
    },
    {
        id = 'scenario-02',
        title = 'SUSPECT\nCONTROL',
        description = 'Practice suspect apprehension and control techniques in various scenarios.',
        duration = 30,
        durationUnit = 'Minutes',
        showDuration = false,
        image = './2.jpg',
        interior = 'tstudio_mrpd_int_garage', -- Replace with actual interior name/hash
        entitysets = { 'scenario_set02' }
    },
    {
        id = 'scenario-03',
        title = 'FLEECA\nROBBERY',
        description = 'Respond to and neutralize an active bank robbery situation.',
        duration = 45,
        durationUnit = 'Minutes',
        showDuration = false,
        image = './3.jpg',
        interior = 'tstudio_mrpd_int_garage', -- Replace with actual interior name/hash
        entitysets = { 'scenario_set03' }
    }
}

Locales = {}


Config.Locale = "en"

Config.Marker = { -- https://docs.fivem.net/docs/game-references/markers/
        type = 2,
        r = 53,
        g = 154,
        b = 71,
        alpha = 50
    }
