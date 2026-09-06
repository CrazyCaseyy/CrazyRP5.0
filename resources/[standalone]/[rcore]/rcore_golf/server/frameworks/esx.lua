if Config.Framework == nil or Config.Framework == 0 then
    if GetResourceState('es_extended') == 'starting' or GetResourceState('es_extended') == 'started' then
        Config.Framework = 1
    end
end

if Config.SocietySystem == 0 then
    if GetResourceState('esx_addonaccount') == 'starting' or GetResourceState('esx_addonaccount') == 'started' then
        Config.SocietySystem = 1
    end
end

if Config.Framework == 1 then
    if Config.FrameworkTriggers['notify'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['notify'])) == 'esx' then
        Config.FrameworkTriggers['notify'] = 'esx:showNotification'
    end

    if Config.FrameworkTriggers['load'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['load'])) == 'esx' then
        Config.FrameworkTriggers['load'] = 'esx:getSharedObject'
    end

    if Config.FrameworkTriggers['resourceName'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['resourceName'])) == 'esx' then
        Config.FrameworkTriggers['resourceName'] = 'es_extended'
    end
end

CreateThread(function()
    if Config.Framework == 1 then
        local ESX = Citizen.Await(GetSharedObjectSafe())

        ShowNotification = function(serverId, msg)
            TriggerClientEvent(Config.FrameworkTriggers['notify'], serverId, msg)
        end

        GetCharacterName = function(serverId)
            local xPlayer = ESX.GetPlayerFromId(serverId)
            local identifier = xPlayer.getIdentifier()
            local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM `users` WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            })

            if result[1] and result[1].firstname and result[1].lastname then
                return ('%s %s'):format(result[1].firstname, result[1].lastname)
            end

            return GetPlayerName(serverId)
        end

        GetCharacterIdentifier = function(serverId)
            local xPlayer = ESX.GetPlayerFromId(serverId)
            return xPlayer.getIdentifier()
        end

        PlayerHasItem = function(serverId, amount)
            local xPlayer = ESX.GetPlayerFromId(serverId)
            if Config.EnableQSInventorySupport then
                local result = exports['qs-inventory']:GetItemTotalAmount(serverId, Config.GolfClubItem)
                return result and result >= amount
            elseif Config.EnableOxInventorySupport then
                return exports.ox_inventory:GetItemCount(serverId, Config.GolfClubItem) >= amount
            else
                local result = xPlayer.getInventoryItem(Config.GolfClubItem)
                return result ~= nil and result.count >= amount
            end
        end

        PlayerHasMoney = function(serverId, amount)
            amount = amount or 0
            return GetPlayerMoney(serverId) >= amount
        end

        GetPlayerMoney = function(serverId)
            return ESX.GetPlayerFromId(serverId).getMoney()
        end

        PlayerTakeMoney = function(serverId, amount, reason)
            amount = amount or 0
            if PlayerHasMoney(serverId, amount) then
                ESX.GetPlayerFromId(serverId).removeMoney(amount)
                return true
            end
            return false
        end

        PlayerGiveMoney = function(serverId, amount, reason)
            amount = amount or 0
            if amount then
                local xPlayer = ESX.GetPlayerFromId(serverId)
                xPlayer.addAccountMoney('money', amount, reason)
            end
        end

        SetVehicleUnlocked = function(serverId, vehicleId) -- For vehicle keys

        end

        AddSocietyMoney = function(amount)
            if not Config.SocietyEnabled then return end

            if Config.SocietySystem == 1 then
                TriggerEvent('esx_addonaccount:getSharedAccount', Config.SocietyName, function(account)
                    if account ~= nil then
                        account.addMoney(amount)
                    end
                end)
            end
        end

        AddWagerCommissionToSociety = function(amount)
            if not Config.SocietyEnabled or not Config.HasWagerCommission then return end

            if Config.SocietySystem == 1 then
                TriggerEvent('esx_addonaccount:getSharedAccount', Config.SocietyName, function(account)
                    if account ~= nil then
                        account.addMoney(amount)
                    end
                end)
            end

            return true
        end

    end
end)