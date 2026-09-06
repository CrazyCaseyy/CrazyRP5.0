Framework = {
    CUSTOM = 0,
    ESX = 1,
    QBCORE = 2,
    STANDALONE = 3,
}

Inventory = {
    AUTOMATIC = 0,
    OX = 1,
    QS = 2,
    MF = 3,
    PS = 4,
    LJ = 5,
    CORE = 6,
    CODEM = 7,
    TGIANN = 8,
    ORIGEN = 9,

    ESX = 100,
    QB = 101,
    STANDALONE = 102,
}

BROADCAST_TYPE = {
    PREPARE_BALLS = "PrepareBalls",
    GIVE_TURN = "GiveTurn",
    PLAYER_ORDER_LIST = "PlayerOrderList",
    AIMER_CHOOSING_STRENGTH = "AimerChoosingStrength",
    CHANGE_AIMER = "ChangeAimer",
    CHANGE_AIMER_STRENGTH = "ChangeAimerStrength",
    FINISHED = "Finished",
    FINAL_BALL_COORDS = "FinalBallCoords",
    STATS_OF_PLAYER_RECEIVED = "StatsOfPlayerReceived",
    TURN_FINISHED = "TurnFinished",
    GOAL = "Goal",
    TURN_STARTED = "TurnStarted",
    LAST_FRAME_SEEN = "LastFrameSeen",
    FRAME_PACK = "FramePack",
}

ALLOWED_BROADCAST_EVENTS = {}
for _, v in pairs(BROADCAST_TYPE) do
    ALLOWED_BROADCAST_EVENTS[v] = true
end

LOBBY_SETTING = {
    TURN_TIME = "turnTime",
    BALL_STYLE = "ballStyle",
    BALL_COLLISION = "ballCollision",
    PLAYER_COLLISION = "playerCollision",
    NEARBY_TRACKS = "nearbyTracks",
}

ALLOWED_LOBBY_SETTINGS = {}
for _, v in pairs(LOBBY_SETTING) do
    ALLOWED_LOBBY_SETTINGS[v] = true
end

InventoryResourceNames = {
    [Inventory.OX] = "ox_inventory",
    [Inventory.QS] = "qs-inventory",
    [Inventory.MF] = "mf-inventory",
    [Inventory.PS] = "ps-inventory",
    [Inventory.LJ] = "lj-inventory",
    [Inventory.CORE] = "core_inventory",
    [Inventory.CODEM] = "codem-inventory",
    [Inventory.TGIANN] = "tgiann-inventory",
    [Inventory.ORIGEN] = "origen_inventory",
}