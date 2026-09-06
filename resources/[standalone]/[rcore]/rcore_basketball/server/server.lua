
RegisterNetEvent('rcore_basketball:requestHoopOwnership', function(hoopId, playerName, gameMode, difficulty, wager)
    local Source = source
    local newState, err = RequestHoopOwnership(Source, hoopId, playerName, gameMode, difficulty, wager)
    if newState then
        SentStateToSubscribers(newState.Id, newState)
    else
        print('rcore_basketball:requestHoopOwnership error', Source, err)
    end
end)

RegisterNetEvent('rcore_basketball:addThrowPoint', function(pos)
    local Source = source
    local newState = AddThrowPoint(Source, pos)

    if newState then
        SentStateToSubscribers(newState.Id, newState)
    else
        print('rcore_basketball:addThrowPoint error')
    end
end)

RegisterNetEvent('rcore_basketball:removeThrowPoint', function(posToRemove)
    local Source = source
    local newState = RemoveThrowPoint(Source, posToRemove)

    if newState then
        SentStateToSubscribers(newState.Id, newState)
    else
        print('rcore_basketball:removeThrowPoint error')
    end
end)

RegisterNetEvent('rcore_basketball:finishHoopSetup', function()
    local Source = source
    local newState = FinishHoopSetup(Source)

    if newState then
        SentStateToSubscribers(newState.Id, newState)
    else
        print('rcore_basketball:finishHoopSetup error')
    end
end)

RegisterNetEvent('rcore_basketball:joinHoop', function(hoopId, name)
    local Source = source
    local newState = JoinHoop(hoopId, Source, name)

    if newState then
        SentStateToSubscribers(newState.Id, newState)
    else
        print('rcore_basketball:joinHoop error')
    end
end)

RegisterNetEvent('rcore_basketball:startHoop', function()
    local Source = source
    local newState = StartHoop(Source)

    if newState then
        SentStateToSubscribers(newState.Id, newState)

        for _, ply in pairs(newState.Players) do
            TriggerClientEvent('rcore_stats:api:increaseStatValue', ply.ServerId, 'basket_hoops_played', 1)
        end
        
    else
        print('rcore_basketball:startHoop error')
    end
end)

RegisterNetEvent('rcore_basketball:pickupBall', function()
    local Source = source
    local hoopState = GetPlayersHoopData(Source)
    
    if hoopState then
        if hoopState.Mode == GAME_ATW then
            if GetCurrentATWTurnPlayerServerId(hoopState) ~= Source then
                print("ERROR: Wrong user trying to pickup ball")
                return
            end
        end
        
        if hoopState.Mode == GAME_HORSE then
            if hoopState.Players[hoopState.CurrentShooter].ServerId ~= Source then
                print("ERROR: Wrong user trying to pickup ball")
                return
            end
        end

        hoopState.DisplayBallResetAt = nil
        hoopState.BallHolderServerId = Source
        
        if Config.TricksRPGProgression then
            SendTricksRPGProgression(Source)
        end

        SentStateToSubscribers(hoopState.Id, hoopState)
    end
end)

function OnPlayerWin(state, winnerServerIndices, wagerReward)
    local partReward = tonumber(math.floor(wagerReward / #winnerServerIndices))

    if Config.AllowWager then
        for _, plyIdx in pairs(winnerServerIndices) do
            local serverId = state.Players[plyIdx].ServerId
            TriggerClientEvent('rcore_stats:api:increaseStatValue', serverId, 'basket_hoops_won', 1)
            if partReward > 0 then
                PlayerGiveMoney(serverId, partReward)
                SendNotification(serverId, string.format(Config.Text.WON_WAGER, partReward))
            else
                SendNotification(serverId, Config.Text.WON_NO_WAGER)
            end
        end
    end
end

function EndGame(hoopStateIdx, hoopState)
    table.remove(State, hoopStateIdx)
    SentStateToSubscribers(hoopState.Id, {Id = hoopState.Id, Status = STATUS_FREE}, true)
end

AddEventHandler('playerDropped', function()
    local Source = source
    RemovePlayerFromAnyOngoingGame(Source)
end)

RegisterCommand('leavebasketball', function(source)
    local Source = source
    RemovePlayerFromAnyOngoingGame(Source)
end, false)

RegisterNetEvent('rcore_basketball:leave', function()
    local Source = source
    RemovePlayerFromAnyOngoingGame(Source)
end)

RegisterNetEvent('rcore_basketball:removePlayer', function(serverId)
    local Source = source
    
    local hoopState = GetPlayersHoopData(Source)

    if hoopState and hoopState.OwnerServerId == Source then
        RemovePlayerFromAnyOngoingGame(serverId)
    end
end)

function SendTricksRPGProgression(Source)
    local score = DbGetScore(GetPlayerIdentifier(Source))

    if not score then
        score = 0
    end

    TriggerClientEvent('rcore_basketball:setTrickAvailable', Source, {
        TRICK_SPIN = score >= Config.TrickScoreRequirement.TRICK_SPIN,
        TRICK_BNR = score >= Config.TrickScoreRequirement.TRICK_BNR,
    })
end

RegisterNetEvent('rcore_basketball:requestOpenSetup', function(hoopId)
    local Source = source

    if PlayerHasItem(Source, Config.BasketballItemName) then
        TriggerClientEvent('rcore_basketball:openNui', Source, {hoopId = hoopId})
    else
        SendNotification(Source, Config.Text.NEED_BASKETBALL)
    end
end)

local statsInited = false

local function setupStats() 
    if not statsInited then
        statsInited = true

        TriggerEvent('rcore_stats:api:ensureCategory', 'minigames', 'Minigames', function()
            TriggerEvent('rcore_stats:api:ensureStatType', "basket_hoops", "Basketball - Points scored", "player", nil, "minigames", true)
            TriggerEvent('rcore_stats:api:ensureStatType', "basket_hoops_won", "Basketball - Games won", "player", nil, "minigames", true)
            TriggerEvent('rcore_stats:api:ensureStatType', "basket_hoops_played", "Basketball - Games played", "player", nil, "minigames", true)

            TriggerEvent('rcore_stats:api:ensureStatType', "total_basket_played", "Basketball - Total games played", "server", nil, "minigames", true, "basket_hoops_played")

            TriggerEvent('rcore_stats:api:ensureAchievement', "basket_hoops_won_1", "Basketball - Game Won", "Win 1 basketball game (not free throw)", "loader-pinwheel", "basket_hoops_won", 1)
            TriggerEvent('rcore_stats:api:ensureAchievement', "basket_hoops_won_5", "Basketball - Upcoming star", "Win 5 basketball games (not free throw)", "loader-pinwheel", "basket_hoops_won", 5)
            TriggerEvent('rcore_stats:api:ensureAchievement', "basket_hoops_won_25", "Basketball - NBA Ready", "Win 25 basketball games (not free throw)", "loader-pinwheel", "basket_hoops_won", 25)

        end)
    end
end

AddEventHandler('rcore_stats:api:ready', setupStats)

CreateThread(function()
    if GetResourceState("rcore_stats") == "started" or GetResourceState("rcore_stats") == "starting" then
        while not statsInited do
            TriggerEvent('rcore_stats:api:isReady', function(isReady)
                if isReady then
                    setupStats()
                end
            end)
            Wait(1000)
        end
    end
end)