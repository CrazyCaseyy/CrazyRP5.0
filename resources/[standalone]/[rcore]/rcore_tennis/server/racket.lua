local TennisRackets = {} -- {[1] = 'desanta'}

-- {
--     desanta = {[1] = true, [2] = true}
-- }
Subscriptions = {}

RegisterNetEvent('rcore_tennis:subscribe', function(courtName)
    local Source = source

    if not Subscriptions[courtName] then
        Subscriptions[courtName] = {}
    end

    if not Subscriptions[courtName][Source] then
        Subscriptions[courtName][Source] = true

        for sid, cname in pairs(TennisRackets) do
            if cname == courtName then
                TriggerClientEvent('rcore_tennis:setTennisRacketInHand', Source, sid)
            end
        end
    end
end)

RegisterNetEvent('rcore_tennis:unsubscribe', function(courtName)
    local Source = source

    UnsubscribeFromCourt(Source, courtName, true)
end)

function RacketOnPlayerDropped(Source, isOnDisconnect)
    TennisRackets[Source] = nil
    
    for courtName, players in pairs(Subscriptions) do
        if players[Source] then
            
            for sid, _ in pairs(players) do
                if not isOnDisconnect or sid ~= Source then
                    TriggerClientEvent('rcore_tennis:unsetTennisRacketInHand', sid, Source)
                end
            end

            if isOnDisconnect then
                UnsubscribeFromCourt(Source, courtName, false)
            end
        end
    end

end

function UnsubscribeFromCourt(serverId, courtName, unsetRacket)
    if Subscriptions[courtName] then
        if Subscriptions[courtName][serverId] then
            Subscriptions[courtName][serverId] = nil

            if unsetRacket then
                for sid, cname in pairs(TennisRackets) do
                    if cname == courtName then
                        TriggerClientEvent('rcore_tennis:unsetTennisRacketInHand', serverId, sid)
                    end
                end
            end
        end
    end
end

RegisterNetEvent('rcore_tennis:requestRacket', function(courtName)
    local Source = source
    TennisRackets[Source] = courtName

    for cname, players in pairs(Subscriptions) do
        for sid, _ in pairs(players) do
            if cname == courtName then
                TriggerClientEvent('rcore_tennis:setTennisRacketInHand', sid, Source)
            end
        end
    end
end)

RegisterNetEvent('rcore_tennis:deleteRacket', function()
    local Source = source
    
    if TennisRackets[Source] then
        for cname, players in pairs(Subscriptions) do
            for sid, _ in pairs(players) do
                if cname == TennisRackets[Source] then
                    TriggerClientEvent('rcore_tennis:unsetTennisRacketInHand', sid, Source)
                end
            end
        end
    end

    TennisRackets[Source] = nil
end)

-- AddEventHandler('playerJoining', function()
--     local Source = source
--     TriggerClientEvent('rcore_tennis:setAllTennisRacketInHand', Source, TennisRackets)
-- end)


