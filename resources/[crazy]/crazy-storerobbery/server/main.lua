local config = require 'config.shared'
local robbingStores = {} -- storeId -> source of the player currently robbing it
local cooldowns = {} -- storeId -> os.time() the store can be robbed again at

lib.callback.register('crazy-storerobbery:server:canRob', function(source, storeId)
    if robbingStores[storeId] then return false end
    if cooldowns[storeId] and cooldowns[storeId] > os.time() then return false end

    robbingStores[storeId] = source
    return true
end)

RegisterNetEvent('crazy-storerobbery:server:cancelRobbery', function(storeId)
    local src = source
    if robbingStores[storeId] == src then
        robbingStores[storeId] = nil
    end
end)

RegisterNetEvent('crazy-storerobbery:server:finishRobbery', function(storeId)
    local src = source
    if robbingStores[storeId] ~= src then return end

    local amount = math.random(config.cashRollsMin, config.cashRollsMax)
    exports.ox_inventory:AddItem(src, 'cash_rolls', amount)
    exports.qbx_core:Notify(src, locale('notify.success'), 'success')

    robbingStores[storeId] = nil
    cooldowns[storeId] = os.time() + math.floor(config.cooldown / 1000)
end)

AddEventHandler('playerDropped', function()
    local src = source
    for storeId, robberSource in pairs(robbingStores) do
        if robberSource == src then
            robbingStores[storeId] = nil
        end
    end
end)
