CreateThread(function()
    if Config.Framework == 3 then
        ShowNotification = function(src, msg)
            TriggerClientEvent("rcore_golf:displayNotification", src, msg)
        end

        GetCharacterName = function(source)
            return GetPlayerName(source)
        end

        GetCharacterIdentifier = function(serverId)
            return serverId
        end

        PlayerHasItem = function(serverId, amount)
            return true
        end

        PlayerHasMoney = function(serverId, amount)
            return true
        end

        GetPlayerMoney = function(serverId)
            return 0
        end

        PlayerTakeMoney = function(serverId, amount, reason)
            return true
        end

        PlayerGiveMoney = function(serverId, amount, reason)
            return true
        end

        SetVehicleUnlocked = function(serverId, vehicleId)
            return true
        end


        AddSocietyMoney = function(amount)
            if not Config.SocietyEnabled then return end
            return true
        end

        AddWagerCommissionToSociety = function(amount)
            if not Config.SocietyEnabled or not Config.HasWagerCommission then return end
            return true
        end

    end
end)