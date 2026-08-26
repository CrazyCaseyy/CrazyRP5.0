-- Tracks how many times each suspect has resisted (failed the cuffing
-- minigame), keyed by their live server id - a fresh count each time
-- they're actually caught, not something meant to persist across
-- reconnects. Server-authoritative so the count can't be reset by the
-- officer's client, and so it holds regardless of which officer is
-- making the attempt.
local resistCounts = {}

lib.callback.register('crazy-minigames:server:getHandcuffResistCount', function(source, targetServerId)
    return resistCounts[targetServerId] or 0
end)

RegisterNetEvent('crazy-minigames:server:handcuffResisted', function(targetServerId)
    resistCounts[targetServerId] = (resistCounts[targetServerId] or 0) + 1
end)

RegisterNetEvent('crazy-minigames:server:resetHandcuffResist', function(targetServerId)
    resistCounts[targetServerId] = nil
end)

AddEventHandler('playerDropped', function()
    resistCounts[source] = nil
end)
