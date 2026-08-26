-- Tracks how many times in a row each player has escaped the handcuff
-- minigame, keyed by their live server id - a fresh streak each time
-- they're actually caught (or escape enough to get overpowered), not
-- something meant to persist across reconnects. Server-authoritative so
-- it can't be manipulated from the client.
local escapeCounts = {}

lib.callback.register('crazy-minigames:server:getHandcuffEscapeCount', function(source, targetServerId)
    return escapeCounts[targetServerId] or 0
end)

RegisterNetEvent('crazy-minigames:server:handcuffEscaped', function(targetServerId)
    escapeCounts[targetServerId] = (escapeCounts[targetServerId] or 0) + 1
end)

RegisterNetEvent('crazy-minigames:server:resetHandcuffEscapes', function(targetServerId)
    escapeCounts[targetServerId] = nil
end)

AddEventHandler('playerDropped', function()
    escapeCounts[source] = nil
end)
