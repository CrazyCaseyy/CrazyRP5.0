local config = require 'config.shared'
local robbingStores = {} -- storeId -> source of the player currently robbing it
local cooldowns = {} -- storeId -> os.time() the store can be robbed again at

local crackingSafes = {} -- storeId -> source of the player currently cracking it
local vaultCooldowns = {} -- storeId -> os.time() the safe can be cracked again at
local vaultAccessible = {} -- storeId -> true once the register's been robbed, until the safe is cracked

lib.callback.register('crazy-storerobbery:server:canRob', function(source, storeId)
    if robbingStores[storeId] then return false end
    if cooldowns[storeId] and cooldowns[storeId] > os.time() then return false end

    robbingStores[storeId] = source
    return true
end)

lib.callback.register('crazy-storerobbery:server:canRobVault', function(source, storeId)
    -- The clerk has to be robbed first every time - cracking the safe once
    -- doesn't leave it open for a second free hit.
    if not vaultAccessible[storeId] then return false, 'locked' end
    if crackingSafes[storeId] then return false, 'cooldown' end
    if vaultCooldowns[storeId] and vaultCooldowns[storeId] > os.time() then return false, 'cooldown' end

    crackingSafes[storeId] = source
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

    vaultAccessible[storeId] = true

    robbingStores[storeId] = nil
    cooldowns[storeId] = os.time() + math.floor(config.cooldown / 1000)
end)

RegisterNetEvent('crazy-storerobbery:server:finishVault', function(storeId)
    local src = source
    if crackingSafes[storeId] ~= src then return end

    local amount = math.random(config.vault.rewardMin, config.vault.rewardMax)
    exports.ox_inventory:AddItem(src, 'cash_band', amount)
    exports.qbx_core:Notify(src, locale('notify.vault_success'), 'success')

    crackingSafes[storeId] = nil
    vaultAccessible[storeId] = nil
    vaultCooldowns[storeId] = os.time() + math.floor(config.vault.cooldown / 1000)
end)

RegisterNetEvent('crazy-storerobbery:server:failVault', function(storeId)
    local src = source
    if crackingSafes[storeId] ~= src then return end

    crackingSafes[storeId] = nil
    vaultCooldowns[storeId] = os.time() + math.floor(config.vault.failCooldown / 1000)
end)

AddEventHandler('playerDropped', function()
    local src = source

    for storeId, robberSource in pairs(robbingStores) do
        if robberSource == src then
            robbingStores[storeId] = nil
        end
    end

    for storeId, robberSource in pairs(crackingSafes) do
        if robberSource == src then
            crackingSafes[storeId] = nil
        end
    end
end)
