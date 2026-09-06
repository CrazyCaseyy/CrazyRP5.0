local statsInited = false

local function setupStats() 
    if not statsInited then
        statsInited = true

        TriggerEvent('rcore_stats:api:ensureCategory', 'minigames', 'Minigames', function()
            TriggerEvent('rcore_stats:api:ensureStatType', "tennis_won", "Tennis - Games won", "player", nil, "minigames", true)
            TriggerEvent('rcore_stats:api:ensureStatType', "tennis_played", "Tennis - Games played", "player", nil, "minigames", true)

            TriggerEvent('rcore_stats:api:ensureStatType', "total_tennis_played", "Tennis - Total games played", "server", nil, "minigames", true, "tennis_played")

            TriggerEvent('rcore_stats:api:ensureAchievement', "tennis_won_1", "Tennis - Game Won", "Win 1 tennis game ", "trophy", "tennis_won", 1)
            TriggerEvent('rcore_stats:api:ensureAchievement', "tennis_won_5", "Tennis - Upcoming Pro", "Win 5 tennis games", "trophy", "tennis_won", 5)
            TriggerEvent('rcore_stats:api:ensureAchievement', "tennis_won_25", "Tennis - Pro", "Win 25 tennis games", "trophy", "tennis_won", 25)
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