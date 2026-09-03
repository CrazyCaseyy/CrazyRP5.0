local config = require 'config.server'
local sharedConfig = require 'config.shared'

local function isPlayerNearBus(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, v in pairs(sharedConfig.npcLocations.locations) do
        local dist = #(coords - vec3(v.x, v.y, v.z))
        if dist < 20 then
            return true
        end
    end
    return false
end

lib.callback.register('qbx_busjob:server:spawnBus', function(source, model, coords)
    local src = source
    local spawnSource = coords or GetPlayerPed(src)

    -- warp needs the actual ped entity to do anything when spawnSource is
    -- coords rather than a ped - a plain `true` only works when
    -- spawnSource itself is a ped (qbx_core/modules/lib.lua).
    local netId = qbx.spawnVehicle({ model = model, spawnSource = spawnSource, warp = GetPlayerPed(src) })
    if not netId or netId == 0 then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then return end

    local plate = locale('info.bus_plate') .. tostring(math.random(1000, 9999))
    SetVehicleNumberPlateText(veh, plate)
    exports.qbx_vehiclekeys:GiveKeys(source, veh)
    return netId
end)

-- Paid on drop-off now, not pickup - a callback (not a fire-and-forget
-- event) so the client can show the actual amount earned in its
-- notification.
lib.callback.register('qbx_busjob:server:NpcPay', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if not isPlayerNearBus(src) then DropPlayer(src, locale('error.exploit_attempt')) return end

    local payment = math.random(15, 25)
    if math.random(1, 100) < config.bonusChance then
        payment = payment + math.random(10, 20)
    end

    local multiplier = exports['crazy-reputation']:GetPayoutMultiplier(src, 'bus')
    payment = math.floor(payment * multiplier)

    player.Functions.AddMoney('cash', payment)
    exports['crazy-reputation']:AddReputation(src, 'bus', 1)

    return payment
end)
