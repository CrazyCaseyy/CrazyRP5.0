local statsInited = false

local function setupStats() 
    if not statsInited then
        statsInited = true

        TriggerEvent('rcore_stats:api:ensureCategory', 'minigames', 'Minigames', function()
            TriggerEvent('rcore_stats:api:ensureStatType', "bowling_won", "Bowling - Games won", "player", nil, "minigames", true)
            TriggerEvent('rcore_stats:api:ensureStatType', "bowling_played", "Bowling - Games played", "player", nil, "minigames", true)
            TriggerEvent('rcore_stats:api:ensureStatType', "bowling_strikes", "Bowling - Strikes", "player", nil, "minigames", true)
            TriggerEvent('rcore_stats:api:ensureStatType', "bowling_spares", "Bowling - Spares", "player", nil, "minigames", true)

            TriggerEvent('rcore_stats:api:ensureStatType', "total_bowling_played", "Bowling - Total games played", "server", nil, "minigames", true, "bowling_played")
            TriggerEvent('rcore_stats:api:ensureStatType', "total_bowling_strikes", "Bowling - Total strikes", "server", nil, "minigames", true, "bowling_strikes")
            TriggerEvent('rcore_stats:api:ensureStatType', "total_bowling_spares", "Bowling - Total spares", "server", nil, "minigames", true, "bowling_spares")

            TriggerEvent('rcore_stats:api:ensureAchievement', "bowling_won_1", "Bowling - Game Won", "Win 1 bowling game ", "loader-pinwheel", "bowling_won", 1)
            TriggerEvent('rcore_stats:api:ensureAchievement', "bowling_won_5", "Bowling - League Player", "Win 5 bowling games", "loader-pinwheel", "bowling_won", 5)
            TriggerEvent('rcore_stats:api:ensureAchievement', "bowling_won_25", "Who do you think you are? I am!", "Win 25 bowling games", "loader-pinwheel", "bowling_won", 25)
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