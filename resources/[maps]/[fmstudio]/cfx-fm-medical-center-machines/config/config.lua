-- //////////////////////////////////////////////////
-- /////////////// Done By Project X ////////////////
-- ///////////////// Our Discord ////////////////////
-- //////// https://discord.gg/bJNxYDAm5u ///////////
-- //////////////////////////////////////////////////

Config = Config or {}
Loc = {}

Config = {
    debug = false,

    Interaction = "ox_target", -- ox_target, qb-target, drawtext
    DisableElevator = false, -- Disable the elevator if you want to use your own script

    CancelKey = "x", -- Key to cancel the animation (default: x)
    CancelCommand = "cancelmre", -- Command to cancel the animation (default: cancelmre)

    -- Drawtext
    Button = "[E] - ", -- For translation only
    DrawtextButton = 38, -- [E] by default
    Drawtext = "OX", -- OLDQB for old qb-drawtext, QB for new qbcore drawtext, OX for ox_lib
    DrawTextZoneSize = vec3(3, 3, 2), -- Size of the drawtext zone
    DrawTextRotation = 90.0, -- Rotation of the drawtext zone

    icon = "fas fa-bed-pulse",
    Labels = {
        ["GoUp"] = "Use the elevator",
        ["GoDown"] = "Use the elevator",
        ["Rad"] = "Use machine",
        ["MRE"] = "Use machine",
        ["Surgery"] = "Lay on bed"
    },

    Distance = 1.0, -- Distance to interact with the object
    Radius = 1.0, -- Radius of the target
}