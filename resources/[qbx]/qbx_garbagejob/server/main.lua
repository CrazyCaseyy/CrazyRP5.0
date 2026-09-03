local config = require 'config.server'
local sharedConfig = require 'config.shared'
local routes = {}

local function canPay(player)
    return player.PlayerData.money.bank >= sharedConfig.truckPrice
end

-- Shared by both solo routes and group lobbies.
local function generateStops()
    local maxStops = math.random(config.minStops, #sharedConfig.locations.trashcan)
    local allStops = {}
    for _ = 1, maxStops do
        local stop = math.random(#sharedConfig.locations.trashcan)
        local newBagAmount = math.random(config.minBagsPerStop, config.maxBagsPerStop)
        allStops[#allStops + 1] = {stop = stop, bags = newBagAmount}
    end
    return allStops
end

lib.callback.register('garbagejob:server:newShift', function(source, continue)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    local shouldContinue = false
    local nextStop = 0
    local totalNumberOfStops = 0
    local bagNum = 0

    if canPay(player) or continue then
        local allStops = generateStops()

        routes[citizenId] = {
            stops = allStops,
            currentStop = 1,
            started = true,
            currentDistance = 0,
            depositPay = sharedConfig.truckPrice,
            actualPay = 0,
            stopsCompleted = 0,
            totalNumberOfStops = #allStops
        }

        nextStop = allStops[1].stop
        shouldContinue = true
        totalNumberOfStops = #allStops
        bagNum = allStops[1].bags

        -- Notify the player about the total number of stops left.
        exports.qbx_core:Notify(source, locale('info.stops_left', totalNumberOfStops), 'info')
    else
        exports.qbx_core:Notify(source, locale('error.not_enough', sharedConfig.truckPrice), 'error')
    end

    return shouldContinue, nextStop, bagNum, totalNumberOfStops
end)

lib.callback.register('garbagejob:server:nextStop', function(source, currentStop, currentStopNum, currLocation)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    local currStopCoords = sharedConfig.locations.trashcan[currentStop].coords
    local distance = #(currLocation - currStopCoords.xyz)
    local newStop = 0
    local shouldContinue = false
    local newBagAmount = 0

    if config.giveItemReward and math.random(100) >= config.itemRewardChance then
        player.Functions.AddItem(config.itemRewardName, 1, false)
        exports.qbx_core:Notify(source, locale('info.found_crypto'))
    end

    if distance <= 20 then
        if currentStopNum >= #routes[citizenId].stops then
            routes[citizenId].stopsCompleted = tonumber(routes[citizenId].stopsCompleted) + 1
            newStop = currentStop
        else
            newStop = routes[citizenId].stops[currentStopNum+1].stop
            newBagAmount = routes[citizenId].stops[currentStopNum+1].bags
            shouldContinue = true
            local bagAmount = routes[citizenId].stops[currentStopNum].bags
            local totalNewPay = 0

            for _ = 1, bagAmount do
                totalNewPay += math.random(config.bagLowerWorth, config.bagUpperWorth)
            end

            routes[citizenId].actualPay = math.ceil(routes[citizenId].actualPay + totalNewPay)
            routes[citizenId].stopsCompleted = tonumber(routes[citizenId].stopsCompleted) + 1

            -- Notify the player about the number of stops left
            local stopsLeft = #routes[citizenId].stops - routes[citizenId].stopsCompleted
            exports.qbx_core:Notify(source, locale('info.stops_left', stopsLeft), 'info')

        end
    else
        exports.qbx_core:Notify(source, locale('error.too_far'), 'error')
    end

    return shouldContinue, newStop, newBagAmount
end)

lib.callback.register('garbagejob:server:endShift', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    return routes[citizenId]
end)

lib.callback.register('garbagejob:server:spawnVehicle', function(source, coords)
    local netId, veh = qbx.spawnVehicle({ spawnSource = coords, model = joaat(config.vehicle), warp = GetPlayerPed(source) })
    local plate = 'GBGE' .. tostring(math.random(1000, 9999))
    SetVehicleNumberPlateText(veh, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    SetVehicleDoorsLocked(veh, 2)
    local player = exports.qbx_core:GetPlayer(source)
    exports.qbx_core:Notify(source, locale(player and not player.Functions.RemoveMoney('bank', sharedConfig.truckPrice, 'garbage-deposit') and 'error.not_enough' or 'info.deposit_paid', sharedConfig.truckPrice), 'error')

    return netId
end)

RegisterNetEvent('garbagejob:server:payShift', function(continue)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local citizenId = player.PlayerData.citizenid
    if routes[citizenId] then
        local depositPay = routes[citizenId].depositPay
        if tonumber(routes[citizenId].stopsCompleted) < tonumber(routes[citizenId].totalNumberOfStops) then
            depositPay = 0
            exports.qbx_core:Notify(src, locale('error.early_finish', routes[citizenId].stopsCompleted, routes[citizenId].totalNumberOfStops), 'error')
        end
        if continue then
            depositPay = 0
        end
        local totalToPay = depositPay + routes[citizenId].actualPay
        local payoutDeposit = locale('info.payout_deposit', depositPay)
        if depositPay == 0 then
            payoutDeposit = ''
        end

        local multiplier = exports['crazy-reputation']:GetPayoutMultiplier(src, 'garbage')
        totalToPay = math.floor(totalToPay * multiplier)

        player.Functions.AddMoney('bank', totalToPay , 'garbage-payslip')
        exports.qbx_core:Notify(src, locale('success.pay_slip', totalToPay, payoutDeposit), 'success')
        exports['crazy-reputation']:AddReputation(src, 'garbage', 1)
        routes[citizenId] = nil
    else
        exports.qbx_core:Notify(source, locale('error.never_clocked_on'), 'error')
    end
end)

-- ===================================================================
-- Group lobbies - solo (routes[citizenid], above) is untouched. A lobby
-- is a shared route + shared truck worked by any number of members, paid
-- out in one lump sum the leader splits by percentage cut per member.
-- ===================================================================

local lobbies = {} -- [lobbyId] = { leaderCid, passcode, members = {[citizenid] = {source, name, cut}}, route, started, vehicleNetId }
local memberLobby = {} -- [citizenid] = lobbyId, for quick lookup

local function getLobbySnapshot(lobbyId)
    local lobby = lobbies[lobbyId]
    if not lobby then return nil end
    local members = {}
    for cid, m in pairs(lobby.members) do
        members[#members + 1] = { citizenid = cid, name = m.name, cut = m.cut, isLeader = cid == lobby.leaderCid }
    end
    return {
        id = lobbyId,
        leaderCid = lobby.leaderCid,
        hasPasscode = lobby.passcode ~= nil,
        members = members,
        started = lobby.started,
    }
end

local function broadcastLobby(lobbyId)
    local lobby = lobbies[lobbyId]
    if not lobby then return end
    local snapshot = getLobbySnapshot(lobbyId)
    for _, m in pairs(lobby.members) do
        TriggerClientEvent('garbagejob:client:lobbyUpdated', m.source, snapshot)
    end
end

-- Whenever the roster changes, reset to an equal split - the leader can
-- still override with setCuts afterwards.
local function rebalanceEqually(lobby)
    local count = 0
    for _ in pairs(lobby.members) do count += 1 end
    if count == 0 then return end
    local share = 100 / count
    for _, m in pairs(lobby.members) do
        m.cut = share
    end
end

local function newLobbyId()
    local id
    repeat
        id = tostring(math.random(100000, 999999))
    until not lobbies[id]
    return id
end

local function playerName(player)
    return ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
end

lib.callback.register('garbagejob:server:createLobby', function(source, passcode)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { error = 'no_player' } end
    local cid = player.PlayerData.citizenid
    if memberLobby[cid] then return { error = 'already_in_lobby' } end

    local lobbyId = newLobbyId()
    lobbies[lobbyId] = {
        leaderCid = cid,
        passcode = (passcode and passcode ~= '') and passcode or nil,
        members = { [cid] = { source = source, name = playerName(player), cut = 100 } },
        route = nil,
        started = false,
        vehicleNetId = nil,
    }
    memberLobby[cid] = lobbyId

    return { lobbyId = lobbyId, snapshot = getLobbySnapshot(lobbyId) }
end)

lib.callback.register('garbagejob:server:listLobbies', function(source)
    local list = {}
    for id, lobby in pairs(lobbies) do
        if not lobby.started then
            local count, leaderName = 0, nil
            for cid, m in pairs(lobby.members) do
                count += 1
                if cid == lobby.leaderCid then leaderName = m.name end
            end
            list[#list + 1] = { id = id, leaderName = leaderName, memberCount = count, hasPasscode = lobby.passcode ~= nil }
        end
    end
    return list
end)

lib.callback.register('garbagejob:server:joinLobby', function(source, lobbyId, passcode)
    local lobby = lobbies[lobbyId]
    if not lobby then return { error = 'not_found' } end
    if lobby.started then return { error = 'already_started' } end
    if lobby.passcode and lobby.passcode ~= passcode then return { error = 'bad_passcode' } end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { error = 'no_player' } end
    local cid = player.PlayerData.citizenid
    if memberLobby[cid] then return { error = 'already_in_lobby' } end

    lobby.members[cid] = { source = source, name = playerName(player), cut = 0 }
    memberLobby[cid] = lobbyId
    rebalanceEqually(lobby)

    local snapshot = getLobbySnapshot(lobbyId)
    broadcastLobby(lobbyId)
    return { lobbyId = lobbyId, snapshot = snapshot }
end)

local function removeLobbyMember(cid)
    local lobbyId = memberLobby[cid]
    if not lobbyId then return end
    local lobby = lobbies[lobbyId]
    memberLobby[cid] = nil
    if not lobby then return end

    local wasLeader = lobby.leaderCid == cid
    lobby.members[cid] = nil

    local remaining = {}
    for remainingCid in pairs(lobby.members) do remaining[#remaining + 1] = remainingCid end

    if #remaining == 0 then
        if lobby.vehicleNetId then
            local veh = NetworkGetEntityFromNetworkId(lobby.vehicleNetId)
            if veh and veh ~= 0 then DeleteEntity(veh) end
        end
        lobbies[lobbyId] = nil
        return
    end

    if wasLeader then
        lobby.leaderCid = remaining[1]
    end
    rebalanceEqually(lobby)
    broadcastLobby(lobbyId)
end

RegisterNetEvent('garbagejob:server:leaveLobby', function()
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local cid = player.PlayerData.citizenid
    TriggerClientEvent('garbagejob:client:lobbyUpdated', source, nil)
    removeLobbyMember(cid)
end)

lib.callback.register('garbagejob:server:setCuts', function(source, cuts)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { error = 'no_player' } end
    local cid = player.PlayerData.citizenid
    local lobbyId = memberLobby[cid]
    local lobby = lobbyId and lobbies[lobbyId]
    if not lobby or lobby.leaderCid ~= cid then return { error = 'not_leader' } end

    local total = 0
    for memberCid in pairs(lobby.members) do
        total += math.max(tonumber(cuts[memberCid]) or 0, 0)
    end
    if total <= 0 then return { error = 'invalid' } end

    for memberCid, m in pairs(lobby.members) do
        m.cut = (math.max(tonumber(cuts[memberCid]) or 0, 0) / total) * 100
    end

    broadcastLobby(lobbyId)
    return { snapshot = getLobbySnapshot(lobbyId) }
end)

lib.callback.register('garbagejob:server:startLobbyShift', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { error = 'no_player' } end
    local cid = player.PlayerData.citizenid
    local lobbyId = memberLobby[cid]
    local lobby = lobbyId and lobbies[lobbyId]
    if not lobby or lobby.leaderCid ~= cid then return { error = 'not_leader' } end
    if lobby.started then return { error = 'already_started' } end

    local stops = generateStops()
    lobby.route = {
        stops = stops,
        currentStop = 1,
        currentStopBagsLeft = stops[1].bags,
        depositPay = sharedConfig.truckPrice,
        actualPay = 0,
        stopsCompleted = 0,
        totalNumberOfStops = #stops,
    }
    lobby.started = true

    return { lobbyId = lobbyId, firstStop = stops[1].stop, totalBags = stops[1].bags }
end)

-- Leader's client spawns the shared truck the same way solo does (via the
-- existing garbagejob:server:spawnVehicle callback, deposit and all), then
-- reports the netId here so it can be relayed to everyone else and
-- deleted server-side at payout.
RegisterNetEvent('garbagejob:server:setLobbyVehicle', function(lobbyId, netId)
    local lobby = lobbies[lobbyId]
    if not lobby or not lobby.route then return end
    lobby.vehicleNetId = netId

    for _, m in pairs(lobby.members) do
        if m.source ~= source then
            TriggerClientEvent('garbagejob:client:lobbyVehicleReady', m.source, netId, lobby.route.stops[1].stop, lobby.route.stops[1].bags)
        end
    end
end)

lib.callback.register('garbagejob:server:lobbyDeliverBag', function(source, lobbyId, currLocation)
    local lobby = lobbies[lobbyId]
    if not lobby or not lobby.route then return { error = 'no_route' } end
    local route = lobby.route

    local currStopCoords = sharedConfig.locations.trashcan[route.stops[route.currentStop].stop].coords
    local distance = #(currLocation - currStopCoords.xyz)
    if distance > 20 then return { error = 'too_far' } end

    if config.giveItemReward and math.random(100) >= config.itemRewardChance then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            player.Functions.AddItem(config.itemRewardName, 1, false)
            exports.qbx_core:Notify(source, locale('info.found_crypto'))
        end
    end

    route.currentStopBagsLeft -= 1
    if route.currentStopBagsLeft > 0 then
        return { cleared = false, bagsLeft = route.currentStopBagsLeft }
    end

    -- Stop cleared - pay in, then advance or finish. Broadcast to every
    -- member (the deliverer included) so nobody's local state drifts.
    local bagAmount = route.stops[route.currentStop].bags
    local totalNewPay = 0
    for _ = 1, bagAmount do
        totalNewPay += math.random(config.bagLowerWorth, config.bagUpperWorth)
    end
    route.actualPay = math.ceil(route.actualPay + totalNewPay)
    route.stopsCompleted += 1

    local result
    if route.currentStop >= #route.stops then
        result = { cleared = true, finished = true }
    else
        route.currentStop += 1
        route.currentStopBagsLeft = route.stops[route.currentStop].bags
        result = {
            cleared = true,
            finished = false,
            nextStop = route.stops[route.currentStop].stop,
            newBagAmount = route.currentStopBagsLeft,
        }
    end

    for _, m in pairs(lobby.members) do
        TriggerClientEvent('garbagejob:client:lobbyStopAdvanced', m.source, result)
    end
    return result
end)

RegisterNetEvent('garbagejob:server:payLobbyShift', function(lobbyId)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local cid = player.PlayerData.citizenid
    if memberLobby[cid] ~= lobbyId then return end

    local lobby = lobbies[lobbyId]
    if not lobby or not lobby.route then return end
    local route = lobby.route

    if route.stopsCompleted < route.totalNumberOfStops then
        exports.qbx_core:Notify(source, locale('error.early_finish', route.stopsCompleted, route.totalNumberOfStops), 'error')
        return
    end

    local depositPay = route.depositPay or 0
    local totalPay = depositPay + route.actualPay

    for memberCid, m in pairs(lobby.members) do
        local share = math.floor(totalPay * (m.cut / 100))
        local multiplier = exports['crazy-reputation']:GetPayoutMultiplier(m.source, 'garbage')
        share = math.floor(share * multiplier)

        local memberPlayer = exports.qbx_core:GetPlayerByCitizenId(memberCid)
        if memberPlayer then
            memberPlayer.Functions.AddMoney('bank', share, 'garbage-payslip-group')
            exports['crazy-reputation']:AddReputation(m.source, 'garbage', 1)
        end
        exports.qbx_core:Notify(m.source, locale('success.pay_slip', share, ''), 'success')
        TriggerClientEvent('garbagejob:client:lobbyEnded', m.source)
        memberLobby[memberCid] = nil
    end

    if lobby.vehicleNetId then
        local veh = NetworkGetEntityFromNetworkId(lobby.vehicleNetId)
        if veh and veh ~= 0 then DeleteEntity(veh) end
    end

    lobbies[lobbyId] = nil
end)

AddEventHandler('playerDropped', function()
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        removeLobbyMember(player.PlayerData.citizenid)
    end
end)

lib.addCommand('cleargarbroutes', {
    help = 'Removes garbo routes for user (admin only)', -- luacheck: ignore
    params = {
        { name = 'id', help = 'Player ID', type = 'playerId' }
    },
    restricted = 'group.admin'
},  function(source, args)
    local player = exports.qbx_core:GetPlayer(args.id)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    local count = 0
    for k in pairs(routes) do
        if k == citizenId then
            count += 1
        end
    end

    exports.qbx_core:Notify(source, locale('success.clear_routes', count), 'success')
    routes[citizenId] = nil
end)
