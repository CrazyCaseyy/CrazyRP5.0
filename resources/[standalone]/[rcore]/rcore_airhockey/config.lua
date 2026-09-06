Config = {
    Locale = "en", -- locales are stored in /locales/
    -- send paddle position to your opponent every 33ms (30x/s)
    -- lower the value for faster sync sync between paddles
    PositionSendRate = 33,
    -- maximum time the puck can stay on one side in ms
    PenaltyTime = 10000,
    -- block these while playing
    RestrictedControls = {37, 157, 159, 160, 161, 162, 163, 164, 165, 158, 101, 337, 53, 54, 47, 140, 141, 263, 264,
                          142, 143, 24, 257, 44, 282, 283, 284, 285, 69, 70, 114, 99, 100, 102, 22, 74, 68, 25, 36, 345,
                          346, 347, 91, 92},
    BounceStrength = 0.15, -- camera bounce effect
    DrawTableScore = true, -- draw actual match score for viewers on top tables
    Framework = 2, -- 0: Standalone (no bets), 1: ESX, 2: QBCore
    EnableBets = true,
    MinBet = 100,
    MaxBet = 5000,
    WinMultiplier = 2, -- winner gets 2x the stake
    SpawnDistance = 30.0,
    UIFontID = 0, -- fontId (used in menus)
    UIFontName = nil, -- name of the font (used in scaleforms and notifications)
    NotifySystem = 5, -- 1: native notify, 2: okokNotify, 3: esx_notify, 4: qb_notify, 5: ox_notify
    -- Enable rcore_stats? (https://store.rcore.cz/package/6273968)
    Rcore_Stats = GetResourceState("rcore_stats") ~= "missing"
}

Objects = {{
    pos = vector3(-1635.939453, -1052.837891, 12.148856),
    heading = 318.0
}, {
    pos = vector3(-1634.047485, -1054.425537, 12.148856),
    heading = 318.0
}}

