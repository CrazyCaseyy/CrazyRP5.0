local config = require 'config.server'
local sharedConfig = require 'config.shared'

-- Fired once, from the flatbed return zone (client/main.lua), when the
-- player presses E to return the flatbed - ends the job and pays out for
-- every delivery made since it started. Not a separate "cash out" trip
-- any more.
RegisterNetEvent('qb-tow:server:cashOut', function(drops)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    -- No longer requires the tow job - anyone can tow. Still requires
    -- actually being at the flatbed hub to cash out (anti-exploit check).
    if #(playerCoords - sharedConfig.locations["vehicle"].coords.xyz) > 8.0 then
        return DropPlayer(source, locale("info.skick"))
    end

    drops = tonumber(drops)
    if not drops or drops <= 0 then return end
    local bonus = 0
    local DropPrice = math.random(150, 170)
    if drops > 5 then
        if drops > 20 then drops = 20 end
        bonus = math.ceil((DropPrice / 10) * ((3 * (drops / 5)) + 2))
    end
    local price = (DropPrice * drops) + bonus
    local taxAmount = math.ceil((price / 100) * config.paymentTax)
    local payment = price - taxAmount

    local multiplier = exports['crazy-reputation']:GetPayoutMultiplier(source, 'tow')
    payment = math.floor(payment * multiplier)

    Player.Functions.AddJobReputation(1)
    Player.Functions.AddMoney("bank", payment, "tow-salary")
    exports['crazy-reputation']:AddReputation(source, 'tow', drops)
    TriggerClientEvent('ox_lib:notify', source, {
      id = 'tow_pay',
      title = 'Job Payment',
      description = locale("success.you_earned", payment),
      showDuration = true,
      position = 'center-right',
      icon = 'check',
      iconColor = '#49c530'
    })
end)

lib.addCommand('npc', {
    help = locale("info.toggle_npc"),
}, function(source)
    TriggerClientEvent("jobs:client:ToggleNpc", source)
end)

-- No longer requires the tow/mechanic job - anyone can use /tow.
lib.addCommand('tow', {
    help = locale("info.tow"),
}, function(source)
    TriggerClientEvent("qb-tow:client:TowVehicle", source)
end)

lib.callback.register('qb-tow:server:spawnVehicle', function(source, model, coords, warp)
    local warpPed = warp and GetPlayerPed(source)
    local netId = qbx.spawnVehicle({model = model, spawnSource = coords, warp = warpPed})
    if not netId or netId == 0 then return end
    return netId
end)

-- Spawns the flatbed at locations.vehicle and hands the player its keys -
-- called from the clipboard ped (client/main.lua) when starting the job.
lib.callback.register('qb-tow:server:startJob', function(source)
    local netId, veh = qbx.spawnVehicle({
        model = joaat('flatbed'),
        spawnSource = sharedConfig.locations["vehicle"].coords,
    })
    if not netId or netId == 0 or not veh or veh == 0 then return end

    exports.qbx_vehiclekeys:GiveKeys(source, veh)
    return netId
end)
