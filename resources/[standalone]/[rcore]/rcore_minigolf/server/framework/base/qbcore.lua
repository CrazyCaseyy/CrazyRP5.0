if Config.Framework.Active == Framework.QBCORE then
    function GetPlayerFrameworkIdentifier(source)
        local playerHandler = GetPlayerHandler(source)
        if playerHandler and playerHandler.PlayerData then
            return playerHandler.PlayerData.citizenid
        end
        return nil
    end

    function GetPlayerHandler(source)
        return SharedObject.Functions.GetPlayer(source)
    end

    function GetPlayerCharacterName(source)
        local player = SharedObject.Functions.GetPlayer(source)
        local playerName = string.format("%s %s", player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)

        return playerName
    end

    function GetPlayerMoney(source, cashType)
        local playerHandler = GetPlayerHandler(source)
        cashType = cashType or CashType.CASH

        if cashType == CashType.CASH then
            return playerHandler.Functions.GetMoney("cash")
        end

        if cashType == CashType.BANK then
            return playerHandler.Functions.GetMoney("bank")
        end

        return 0
    end

    function AddPlayerMoney(source, cashType, money)
        local playerHandler = GetPlayerHandler(source)
        cashType = cashType or CashType.CASH

        if cashType == CashType.CASH then
            playerHandler.Functions.AddMoney("cash", money)
        end

        if cashType == CashType.BANK then
            playerHandler.Functions.AddMoney("bank", money)
        end
    end

    function RemovePlayerMoney(source, cashType, money)
        local playerHandler = GetPlayerHandler(source)
        cashType = cashType or CashType.CASH

        if cashType == CashType.CASH then
            playerHandler.Functions.RemoveMoney("cash", money)
        end

        if cashType == CashType.BANK then
            playerHandler.Functions.RemoveMoney("bank", money)
        end
    end

    function GetPlayerRealName(source)
        local playerHandler = GetPlayerHandler(source)
        local name = nil
       
        if playerHandler.PlayerData.charinfo and playerHandler.PlayerData.charinfo.firstname then
            return playerHandler.PlayerData.charinfo.firstname
        else
            return playerHandler.PlayerData.name
        end
    
        if not name then
            name = GetPlayerName(source)
        end
        
        return name
    end
end