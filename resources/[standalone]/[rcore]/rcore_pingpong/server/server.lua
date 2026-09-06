local tables = {}
local playerStates = {}
local gameUID = 0
local routingBuckets = {}

-- is anyone waiting for opponent on table
local function IsAnyoneChallengingGame(t)
    for k, v in pairs(playerStates) do
        if v.isChallenging and v.nearbyTable == t then
            return true
        end
    end
    return false
end

local function RefreshPlayerRoutingBuckets()
    for _, playerId in ipairs(GetPlayers()) do
        local playerId = tonumber(playerId)
        local bucket = GetPlayerRoutingBucket(playerId)
        if routingBuckets[playerId] ~= bucket then
            routingBuckets[playerId] = bucket
            TriggerClientEvent("TableTennis:UpdateRoutingBucket", playerId, bucket)
        end
    end
end

-- get or create player state
local function GetPlayerState(playerId)
    if not playerStates[playerId] then
        local license = GetPlayerIdentifierByType(playerId, Config.PlayerIdentifier)
        if not license then
            license = ""
            print("[Table Tennis] Player identifier '" .. Config.PlayerIdentifier ..
                      "' wasn't found. Set the correct player identifier key in config.lua")
        end
        local playerName = GetPlayerRealName(playerId)
        playerStates[playerId] = {
            license = license,
            mugShot = "-1",
            name = playerName,
            interactableTable = nil,
            isChallenging = false,
            nearbyTable = nil,
            settings = {
                racketSkin = 0
            }
        }
    end
    return playerStates[playerId]
end

-- finish pvp game
local function FinalizeGame(t)
    if t.state ~= "started" then
        return
    end
    -- add wins/losses to leaderboard
    local winners, losers = {}, {}
    local affectLeaderboard = Config.UseLeaderboard and not t.againstBot and t.matchSettings.useLeaderboard
    local gameDurationMS = GetGameTimer() - t.startedTime
    local maxScore = t.matchSettings.maxRounds
    if t.matchSettings.gamemode == 4 then
        maxScore = 61
    elseif t.matchSettings.gamemode == 5 then
        maxScore = 100
    end
    if gameDurationMS < 15000 then
        affectLeaderboard = false
    end
    if t.aborted then
        maxScore = 0
        for i = 1, 2, 1 do
            if t.players[i].score > maxScore then
                maxScore = t.players[i].score
            end
        end
    end

    if maxScore > 0 then
        for i = 1, 2, 1 do
            local myP = t.players[i]
            local opP = t.players[i == 1 and 2 or 1]
            if t.players[i].score >= maxScore and not t.players[i].disconnected then
                table.insert(winners, myP)
                if affectLeaderboard then

                    local pS = GetPlayerState(myP.playerId)
                    if pS.stake > 0 then
                        local winnings = pS.stake * 2
                        GivePlayerMoney(myP.playerId, winnings)
                        pS.stake = 0
                    end

                    Leaderboards:AddWin(myP, opP)
                end
            else
                table.insert(losers, myP)
                if affectLeaderboard then
                    Leaderboards:AddLoss(myP, opP)
                end
            end
        end

        t.broadcastSubscribers("TableTennis:Finished", t.coords, t.routingBucket, winners, losers, t.aborted)
    end
end

-- finalize & reset table on coords
local function DeleteTableOnCoords(tableCoords, bucket)
    local useBucket = bucket ~= nil
    for i, tableData in ipairs(tables) do
        if #(tableCoords - tableData.coords) < 0.2 then
            local tableBucket = tableData.routingBucket or 0
            if useBucket and tableBucket ~= bucket then
                goto continue
            end
            if tableData.state == "started" then
                FinalizeGame(tableData)
            end
            tableData.aborted = false
            tableData.state = "created"
            tableData.players = nil
            tableData.broadcastSubscribers("TableTennis:TableRemoved", tableCoords, tableBucket)
            TriggerClientEvent("TableTennis:TableRecordRemove", -1, tableCoords, tableBucket)
            break
        end
        ::continue::
    end
end

-- finds table instance at coords
local function FindTableOncoords(tableCoords, bucket)
    local useBucket = bucket ~= nil
    -- find existing
    for _, tableData in ipairs(tables) do
        if #(tableCoords - tableData.coords) < 0.2 then
            local tableBucket = tableData.routingBucket or 0
            if not useBucket or tableBucket == bucket then
                return tableData
            end
        end
    end
    return nil
end

-- gets or creates a tennis game at the coords
local function GetOrCreateTable(tableCoords, tableHeading, tableModel, tableSkin, bucket)
    -- find existing
    local t = FindTableOncoords(tableCoords, bucket)
    if t then
        return t
    end
    if not tableModel then
        return nil
    end
    if bucket == nil then
        bucket = 0
    end
    -- crate new
    gameUID = gameUID + 1
    local o = {
        subscribers = {},
        nearby = {},
        coords = tableCoords,
        state = "created",
        id = gameUID,
        heading = tableHeading,
        model = tableModel,
        skin = tableSkin,
        routingBucket = bucket
    }

    -- check if player is the host of game
    o.isHost = function(playerId)
        if not o.players then
            return false
        end
        for i = 1, 2 do
            if o.players[i] and o.players[i].host and o.players[i].playerId == playerId then
                return true
            end
        end
        return false
    end

    -- get side of player
    o.getSide = function(playerId)
        if not o.players then
            return nil
        end
        for i = 1, 2 do
            if o.players[i] and o.players[i].playerId == playerId then
                return i
            end
        end
        return nil
    end

    -- send event to both players
    o.broadcastPlayers = function(eventName, ...)
        if not o.players then
            return
        end
        for k, v in pairs(o.players) do
            TriggerClientEvent(eventName, v.playerId, ...)
        end
    end

    -- send event to everyone on the list
    o.broadcastList = function(t, eventName, ...)
        for k, v in pairs(t) do
            TriggerClientEvent(eventName, k, ...)
        end
    end

    -- send event to all watchers/players
    o.broadcastSubscribers = function(eventName, ...)
        o.broadcastList(o.subscribers, eventName, ...)
    end

    -- send event to all watchers/players
    o.broadcastNearbies = function(eventName, ...)
        o.broadcastList(o.nearby, eventName, ...)
    end

    -- add/remove subscriber
    o.toggleSubscriber = function(playerId, toggle)
        if not toggle then
            toggle = nil
        end
        o.subscribers[playerId] = toggle

        local inTotal = 0
        for k, v in pairs(o.subscribers) do
            inTotal = inTotal + 1
        end
    end

    -- add/remove nearby
    o.toggleNearby = function(playerId, toggle)
        if not toggle then
            toggle = nil
        end
        o.nearby[playerId] = toggle
    end

    table.insert(tables, o)
    return o
end

-- gets tennis game of the player
local function FindTableOfPlayer(playerId)
    for _, tableData in ipairs(tables) do
        local players = tableData.players
        if players then
            for _, playerData in ipairs(players) do
                if playerData.playerId == playerId then
                    return tableData
                end
            end
        end
    end
    return nil
end

-- player requests to play with bot
RegisterNetEvent("TableTennis:StartAgainstBot")
AddEventHandler("TableTennis:StartAgainstBot",
    function(tableCoords, side, netId, botModel, tableHeading, tableModel, tableSkin)
        local playerId = source
        if FindTableOfPlayer(playerId) then
            return
        end
        local bucket = routingBuckets[playerId]
        if bucket == nil then
            bucket = GetPlayerRoutingBucket(playerId)
        end
        local game = GetOrCreateTable(tableCoords, tableHeading, tableModel, tableSkin, bucket)

        if IsAnyoneChallengingGame(game) then
            TriggerClientEvent("TableTennis:StartAgainstBot", playerId, "AlreadyChallenging")
            return
        end

        if game.state ~= "created" then
            return
        end

        local kS = GetPlayerState(playerId)
        kS.stake = 0

        game.players = {}
        game.players[side] = {
            name = kS.name,
            license = kS.license,
            playerId = playerId,
            netId = netId,
            host = true,
            side = side,
            score = 0
        }

        -- join bot
        for i = 1, 2 do
            if not game.players[i] then
                game.players[i] = {
                    name = "Bot",
                    playerId = -2,
                    host = false,
                    side = (side == 1 and 2 or 1),
                    isBot = true,
                    score = 0,
                    skin = botModel
                }
            end
        end

        game.hostSide = side

        game.matchSettings = {
            maxRounds = 123,
            ball = 1,
            speed = 1,
            helper = true,
            useLeaderboard = false,
            netHitBox = true
        }

        game.state = "localpreparing"
        game.againstBot = true
        game.key = getUID()
        game.startedTime = GetGameTimer()
        game.broadcastPlayers("TableTennis:Started", game)
        TriggerClientEvent("TableTennis:TableRecordAdd", -1, game.key, tableCoords, tableHeading, tableModel, tableSkin,
            bucket)
    end)

-- host sent snapshot for watchers
RegisterNetEvent("TableTennis:SnapPack")
AddEventHandler("TableTennis:SnapPack", function(snapPack)
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t or not t.players then
        return
    end
    local isHost = false

    for i = 1, 2 do
        if t.players[i] and t.players[i].host and t.players[i].playerId == playerId then
            isHost = true
        end
    end

    if not isHost then
        return
    end
    t.broadcastSubscribers("TableTennis:SnapPack", t.coords, t.routingBucket, snapPack)
end)

-- player subscribes/unsubscribes for game events
RegisterNetEvent("TableTennis:Subscribe")
AddEventHandler("TableTennis:Subscribe", function(coords, toggle, tableHeading, tableModel, tableSkin, tableBucket)
    local playerId = source
    local bucket = tableBucket
    if bucket == nil then
        bucket = routingBuckets[playerId]
        if bucket == nil then
            bucket = GetPlayerRoutingBucket(playerId)
        end
    end
    local t = GetOrCreateTable(coords, tableHeading, tableModel, tableSkin, bucket)
    if not t then
        return
    end
    t.toggleSubscriber(playerId, toggle)

    if toggle then
        if t.state == "started" then
            TriggerClientEvent("TableTennis:StartedData", playerId, t)
        end
    end
end)

-- host sends mugshots of players
RegisterNetEvent("TableTennis:UpdateMugshots")
AddEventHandler("TableTennis:UpdateMugshots", function(mug1, mug2)
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    if not t.isHost(playerId) then
        return
    end
    if not mug1 then
        mug1 = ""
    end
    if not mug2 then
        mug2 = ""
    end
    t.players[1].mugShot = mug1
    t.players[2].mugShot = mug2

    -- send mugshots to all watchers/players
    t.broadcastSubscribers("TableTennis:Mugshots", t.coords, t.routingBucket, mug1, mug2)
end)

-- host synces match settings menu with opponent
RegisterNetEvent("TableTennis:SyncTennisMenu")
AddEventHandler("TableTennis:SyncTennisMenu", function(sharedSettings)
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    if not t.isHost(playerId) then
        return
    end
    -- send shared settings to the opponent
    for i = 1, 2, 1 do
        if t.players[i] and not t.players[i].host then
            TriggerClientEvent("TableTennis:SyncTennisMenu", t.players[i].playerId, sharedSettings)
        end
    end
end)

-- peerjs failed
RegisterNetEvent("TableTennis:SwitchToFivem")
AddEventHandler("TableTennis:SwitchToFivem", function()
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    if not t.isHost(playerId) then
        return
    end
    if t.state ~= "started" then
        return
    end
    t.state = "p2pready"
    for k, v in pairs(t.players) do
        local kS = GetPlayerState(v.playerId)
        kS.peerId = nil
    end

    t.useFivem = true
    t.startedTime = GetGameTimer()
    t.broadcastPlayers("TableTennis:Started", t)
end)

-- player presses ready
RegisterNetEvent("TableTennis:Ready")
AddEventHandler("TableTennis:Ready", function(matchSettings, playerSettings)
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    if t.againstBot and t.state ~= "localpreparing" then
        return
    elseif not t.againstBot and t.state ~= "preparing" then
        return
    end

    local ps = GetPlayerState(playerId)
    if ps then
        ps.settings = playerSettings
    end

    local playersReady = 0
    for k, v in pairs(t.players) do
        if v.playerId == playerId then
            v.ready = true
            if ps then
                v.settings = ps.settings
            end
        end
        if v.ready then
            playersReady = playersReady + 1
        end
    end
    -- host saves match settings here as well
    if t.isHost(playerId) then
        t.matchSettings = {
            maxRounds = tonumber(matchSettings.finalScore),
            ball = tonumber(matchSettings.ball),
            speed = tonumber(matchSettings.speed),
            helper = matchSettings.helper,
            useLeaderboard = matchSettings.useLeaderboard,
            netHitBox = matchSettings.netHitBox,
            gamemode = tonumber(matchSettings.gamemode)
        }
        if t.matchSettings.gamemode == 4 then
            t.matchSettings.ball = 5
        end
        t.broadcastPlayers("TableTennis:MatchSettings", t.coords, t.routingBucket, t.matchSettings)
    end
    if t.againstBot then
        t.state = "started"
        t.broadcastSubscribers("TableTennis:StartedData", t)
    elseif playersReady == 2 then
        t.state = "p2pready"
        t.broadcastSubscribers("TableTennis:MatchSettings", t.coords, t.routingBucket, t.matchSettings)
        t.key = getUID()
        t.startedTime = GetGameTimer()
        t.broadcastPlayers("TableTennis:Started", t)
        TriggerClientEvent("TableTennis:TableRecordAdd", -1, t.key, t.coords, t.heading, t.model, t.skin,
            t.routingBucket)
    end
end)

-- reste nearby state to nearby players
local function ResendNearbyState(t)
    local nearbyList = {}
    for k, v in pairs(t.nearby) do
        local kS = GetPlayerState(k)
        table.insert(nearbyList, {
            name = kS.name,
            mugShot = kS.mugShot,
            playerId = k,
            isChallenging = kS.isChallenging
        })
    end
    t.broadcastNearbies("TableTennis:NearbyStateUpdated", nearbyList, t.state)
end

-- when player comes to the table/leaves the table
RegisterNetEvent("TableTennis:ToggleInteractable")
AddEventHandler("TableTennis:ToggleInteractable", function(coords)
    local playerId = source
    local s = GetPlayerState(playerId)
    s.isChallenging = false
    s.peerId = nil
    local affectedTable = nil
    if coords then
        -- stop if already in game / already challenging a friend
        local playingTable = FindTableOfPlayer(playerId)
        if playingTable then
            return
        end
        if s.isChallenging then
            return
        end
        -- get / create game controller at coords
        local bucket = routingBuckets[playerId]
        if bucket == nil then
            bucket = GetPlayerRoutingBucket(playerId)
        end
        local t = GetOrCreateTable(coords, nil, nil, nil, bucket)
        if not t then
            return
        end
        s.nearbyTable = t
        affectedTable = t
        t.toggleNearby(playerId, true)

    elseif s.nearbyTable then
        affectedTable = s.nearbyTable
        s.nearbyTable = nil
        -- s.isChallenging = false
        affectedTable.toggleNearby(playerId, nil)
    end

    -- resend nearby players a new state (who is next to the table, if anyone)
    if affectedTable then
        local nearbyList = {}
        for k, v in pairs(affectedTable.nearby) do
            local kS = GetPlayerState(k)
            table.insert(nearbyList, {
                name = kS.name,
                mugShot = kS.mugShot,
                playerId = k
            })
        end
        ResendNearbyState(affectedTable)
    end
end)

-- when player comes to the table and presses E
RegisterNetEvent("TableTennis:ChallengePlayer")
AddEventHandler("TableTennis:ChallengePlayer", function(netId, prefferedSide)
    local playerId = source
    local s = GetPlayerState(playerId)
    if not s.nearbyTable then
        return
    end
    local game = s.nearbyTable
    if game.state ~= "created" then
        return
    end
    if s.isChallenging then
        return
    end
    s.netId = netId
    s.isChallenging = true
    s.prefferedSide = prefferedSide
    s.challengeTime = GetGameTimer()
    s.stake = 0

    ResendNearbyState(game)

    -- check if both players clicked E
    local challengingCount = 0
    for k, v in pairs(game.nearby) do
        local kS = GetPlayerState(k)
        if kS.isChallenging then
            challengingCount = challengingCount + 1
        end
    end
    if challengingCount == 2 and game.state == "created" then

        for k, v in pairs(game.nearby) do
            local kS = GetPlayerState(k)
            kS.isChallenging = nil
        end

        game.useFivem = false
        game.state = "preparing"
        game.hostSide = 1
        game.players = {}
        game.stakePaid = false

        for k, v in pairs(game.nearby) do
            local kS = GetPlayerState(k)
            local lS = Config.UseLeaderboard and Leaderboards.Data[kS.license]
            local wins = lS and lS.wins or 0
            local losses = lS and lS.losses or 0

            -- Create a new player entry
            local player = {
                license = kS.license,
                name = kS.name,
                playerId = k,
                netId = kS.netId,
                host = false,
                side = kS.prefferedSide,
                score = 0,
                mugShot = kS.mugShot,
                challengeTime = kS.challengeTime,
                wins = wins,
                losses = losses
            }

            -- Add the player to the game
            table.insert(game.players, player)
        end

        -- Sort the players by challengeTime in ascending order
        table.sort(game.players, function(a, b)
            return a.challengeTime < b.challengeTime
        end)

        -- Check if there are at least 2 players
        if #game.players >= 2 then
            -- Set host to true for the player with the sooner challengeTime
            game.players[1].host = true

            -- Check if the player with sooner challengeTime chose side 2
            if game.players[1].side == 2 then
                -- Swap the players to ensure the one choosing side 2 is at index 2
                game.hostSide = 2
                game.players[1], game.players[2] = game.players[2], game.players[1]
            end
        end

        for i = 1, 2, 1 do
            game.players[i].side = i
        end

        game.againstBot = false

        for k, v in pairs(game.players) do
            local pBalance = GetPlayerMoney(v.playerId)
            TriggerClientEvent("TableTennis:PreparePVP", v.playerId, game, pBalance)
        end
        game.broadcastSubscribers("TableTennis:StartedData", game)
    end
end)

local GetPlayerRoutingBucket_ = GetPlayerRoutingBucket
function GetPlayerRoutingBucket(playerId)
    if Config.UseRoutingBuckets then
        return GetPlayerRoutingBucket_(playerId)
    else
        return 0
    end
end

-- request match settings for table
RegisterNetEvent("TableTennis:RequestMatchSettings")
AddEventHandler("TableTennis:RequestMatchSettings", function(coords)
    local playerId = source
    local bucket = routingBuckets[playerId]
    if bucket == nil then
        bucket = GetPlayerRoutingBucket(playerId)
    end
    local t = FindTableOncoords(coords, bucket)
    if not t then
        return
    end
    TriggerClientEvent("TableTennis:MatchSettings", playerId, t.coords, t.routingBucket, t.matchSettings)
end)

-- player aborts their game
RegisterNetEvent("TableTennis:AbortGame")
AddEventHandler("TableTennis:AbortGame", function()
    local playerId = source
    local s = GetPlayerState(playerId)
    s.isChallenging = false
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    t.aborted = true
    DeleteTableOnCoords(t.coords, t.routingBucket)
end)

-- host updates scores
RegisterNetEvent("TableTennis:UpdateScores")
AddEventHandler("TableTennis:UpdateScores", function(data)
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    if t.state ~= "started" then
        return
    end
    if not t.isHost(playerId) then
        return
    end
    local data = json.decode(decrypt(data, t.key))
    local k = decrypt(data.k, "ttennis")
    local winnerScore = t.matchSettings.maxRounds
    if t.matchSettings.gamemode == 4 then
        winnerScore = 61
    elseif t.matchSettings.gamemode == 5 then
        winnerScore = 100
    end
    if k == t.key then
        local s1 = tonumber(data.s1)
        local s2 = tonumber(data.s2)
        if not s1 or not s2 then return end
        s1 = math.floor(s1)
        s2 = math.floor(s2)
        if s1 < 0 or s2 < 0 or s1 > winnerScore or s2 > winnerScore then return end
        if s1 < t.players[1].score or s2 < t.players[2].score then return end
        t.players[1].score = s1
        t.players[2].score = s2
    end
    local matchFinished = false
    for i = 1, 2, 1 do
        if t.players[i].score >= winnerScore then
            matchFinished = true
            break
        end
    end

    if matchFinished then
        DeleteTableOnCoords(t.coords, t.routingBucket)
    end
end)

-- player shares their mugshot for other players
RegisterNetEvent("TableTennis:PlayerMugshot")
AddEventHandler("TableTennis:PlayerMugshot", function(mugShot)
    local playerId = source
    local s = GetPlayerState(playerId)
    if type(mugShot) ~= "string" or #mugShot > 10000 then
        return
    end
    local lower = mugShot:lower()
    if lower:find("^javascript:") or lower:find("^vbscript:") or lower:find("^data:text/") or lower:find("^data:image/svg") then
        return
    end
    s.mugShot = mugShot
end)

-- Billiard Gamemode: Model has changed
RegisterNetEvent("TableTennis:LastBilliardModel")
AddEventHandler("TableTennis:LastBilliardModel", function(model)
    local playerId = source
    local t = FindTableOfPlayer(playerId)
    if not t then
        return
    end
    if not t.isHost(playerId) then
        return
    end
    t.lastBilliardModel = model
end)

-- player shares their mugshot for other players
RegisterNetEvent("TableTennis:ConfirmStake")
AddEventHandler("TableTennis:ConfirmStake", function(stake)
    stake = tonumber(stake)
    stake = math.floor(stake)
    if not Config.EnableBetting or stake > Config.MaxBet or stake < Config.MinBet then
        return
    end
    local playerId = source
    local pS = GetPlayerState(playerId)
    local pMoney = GetPlayerMoney(playerId)
    if pMoney > stake then
        pS.stake = stake
    end
end)

-- player requests top players data
RegisterNetEvent("TableTennis:RequestTopPlayers")
AddEventHandler("TableTennis:RequestTopPlayers", function()
    local playerId = source
    if not Config.UseLeaderboard then
        return
    end
    local ps = GetPlayerState(playerId)
    if not ps then
        return
    end
    if ps.topRequestTime and GetGameTimer() - ps.topRequestTime < 1000 then
        return
    end
    ps.topRequestTime = GetGameTimer()

    local ownProfile = {
        name = GetPlayerRealName(playerId),
        wins = 0,
        losses = 0,
        mug = ps and ps.mugShot or nil
    }

    if Leaderboards.Data[ps.license] then
        ownProfile.wins = Leaderboards.Data[ps.license].wins
        ownProfile.losses = Leaderboards.Data[ps.license].losses
        ownProfile.mug = Leaderboards.Data[ps.license].mug
    end

    TriggerClientEvent("TableTennis:TopPlayers", playerId, Leaderboards.Tops, ownProfile)
end)

-- player shares shares their peerID with opponent
RegisterNetEvent("TableTennis:PeerID")
AddEventHandler("TableTennis:PeerID", function(peerId)
    local playerId = source
    local pS = GetPlayerState(playerId)
    pS.peerId = peerId

    -- share peer ids
    local t = FindTableOfPlayer(playerId)
    if t then
        local peers = 0
        local lowestStake = Config.MaxBet
        for k, v in pairs(t.players) do
            local kS = GetPlayerState(v.playerId)
            if kS.peerId then
                peers = peers + 1
                if v.playerId == playerId then
                    v.peerId = kS.peerId
                end
            end
            if kS.stake and kS.stake < lowestStake then
                lowestStake = kS.stake
            end
        end
        if peers == 2 and t.state == "p2pready" then
            if lowestStake > 0 and lowestStake <= Config.MaxBet and not t.stakePaid then
                -- pay stakes, if any
                local enoughMoney = true
                for k, v in pairs(t.players) do
                    local pM = GetPlayerMoney(v.playerId)
                    if pM < lowestStake then
                        enoughMoney = false
                    end
                end

                for k, v in pairs(t.players) do
                    local kS = GetPlayerState(v.playerId)
                    if enoughMoney then
                        kS.stake = lowestStake
                        RemovePlayerMoney(v.playerId, lowestStake)
                    else
                        kS.stake = 0
                    end
                end
            else
                for k, v in pairs(t.players) do
                    local kS = GetPlayerState(v.playerId)
                    kS.stake = 0
                end
            end

            t.stakePaid = true
            t.state = "started"
            t.broadcastPlayers("TableTennis:PeerIDs", t.players)
        end
    end
end)

-- player requests table records on connect
RegisterNetEvent("TableTennis:GetTableRecords")
AddEventHandler("TableTennis:GetTableRecords", function()
    local playerId = source
    local records = {}
    for _, t in ipairs(tables) do
        if t.state == "started" then
            table.insert(records, {
                key = t.key,
                coords = t.coords,
                heading = t.heading,
                model = t.model,
                skin = t.skin,
                routingBucket = t.routingBucket
            })
        end
    end
    TriggerClientEvent("TableTennis:TableRecords", playerId, records)
end)

-- player disconnected, deleting their casino progress
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local s = GetPlayerState(playerId)

    s.interactableTable = nil
    s.isChallenging = false

    if s.nearbyTable then
        s.nearbyTable.toggleNearby(playerId, nil)
        s.nearbyTable.toggleSubscriber(playerId, false)
    end
    s.nearbyTable = nil

    local t = FindTableOfPlayer(playerId)
    if t then
        t.aborted = true
        DeleteTableOnCoords(t.coords, t.routingBucket)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        RefreshPlayerRoutingBuckets()
    end
end)
