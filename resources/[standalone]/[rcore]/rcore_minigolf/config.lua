Config = {
    -- Locales of the resource
    Locales = "en",

    -- Main Settings
    ShowGolfBlips = true, -- show blips for minigolf courses
    GolfReadyBlip = 358, -- blip id for ready minigolf course
    GolfUnbuiltBlip = 109, -- blip id for unbuilt minigolf course
    LastPlayerTurnTime = 60, -- time in seconds before the last player's turn ends

    MiniGolfBuildingRenderDistance = 80.0, -- this is how far away player have to be from the minigolf course to spawn in / out

    -- Builders 
    -- 1 = one builder builds the whole minigolf at once,
    -- 2 = multiple builders can build piece by piece
    BuildMode = 1,
    BuildResetsLeaderboards = true, -- will reset leaderboards when re-building minigolf

    -- Inventory items
    TurfInventoryItem = "minigolf_turf", -- turf item name
    ObstacleInventoryItem = "minigolf_obstacle", -- obstacle item name
    TurfCost = 100, -- turf item cost
    ObstacleCost = 100, -- obstacle item cost

    -- Save Data
    SaveDataPath = "server/minigolf.json", -- path to save data file
    LeaderboardsDataPath = "server/leaderboards.json", -- path to leaderboards data file
    MugshotsDataPath = "server/mugshots.json", -- path to mugshots data file

    -- Lobby
    MinLobbyPlayers = 1, -- min players in a lobby
    MaxLobbyPlayers = 6, -- max players in a lobby

    ReplayFrameRate = 30, -- replay frame records every 30ms
    ReplayPackLength = 10, -- replay sends 10 frames at a time

    -- Gameplay
    Keys = {
        AimLeft = 34, -- A
        AimRight = 35, -- D
        Shoot = 22 -- SPACE
    },
    MouseYInvert = false, -- invert mouse Y axis when aiming

    -- 1 = based on shoots in total only,
    -- 2 = based on shoots in total + bonus points when player scores goal before their opponents
    ScoringType = 1,

    OutOfBoundsDistance = 8.0, -- distance from the minigolf course that is considered out of bounds
    -- [[[[[[[       WARNING       ]]]]]]]
    -- THIS configuration is automatic, you dont need to configure this at all. Configure this only if you need to force specific inventory.
    -- [[[[[[[       WARNING       ]]]]]]]
    -- Inventory System
    -- Inventory.AUTOMATIC      = automatic detection
    -- Inventory.OX             = ox_inventory
    -- Inventory.ESX            = esx_inventory
    -- Inventory.QB             = qb_inventory
    -- Inventory.QS             = qs_inventory
    -- Inventory.MF             = mf_inventory
    -- Inventory.PS             = ps_inventory
    -- Inventory.LJ             = lj_inventory
    -- Inventory.CORE           = core_inventory
    -- Inventory.CODEM          = codem-inventory
    -- Inventory.TGIANN         = tgiann-inventory
    -- Inventory.ORIGEN         = origen
    -- Inventory.STANDALONE     = standalone inventory settings
    InventorySystem = Inventory.OX,

    RestockMissionEnabled = false
}

Config.SpawnObject = {{
    model = GetHashKey("prop_table_03"),
    pos = vec3(-1346.0, -1235.76, 4.94),
    heading = 291.74,
    renderDistance = 50.0
}}

Config.Framework = {
    -- 1 = esx
    -- 2 = qbcore
    -- 3 = standalone
    Active = 2,

    -- esx
    ESX_SHARED_OBJECT = "esx:getSharedObject",

    -- es_extended resource name
    ES_EXTENDED_NAME = "es_extended",

    -------
    -- qbcore
    QBCORE_SHARED_OBJECT = "QBCore:GetObject",

    -- qb-core resource name
    QB_CORE_NAME = "qb-core",

    -- will not detect any supported framework if on true.
    DisableDetection = false
}

-- framework events
Config.Events = {
    QBCore = {
        playerLoaded = "QBCore:Client:OnPlayerLoaded",
        playerLoadedServer = "QBCore:Server:OnPlayerLoaded",
        jobUpdate = "QBCore:Client:OnJobUpdate"
    },
    ESX = {
        playerDropped = "esx:playerDropped",
        playerLoaded = "esx:playerLoaded",
        playerLogout = "esx:playerLogout",
        jobUpdate = "esx:setJob"
    }
}

Config.StandaloneSettings = {
    DefaultIdentifierType = "fivem:"
}
