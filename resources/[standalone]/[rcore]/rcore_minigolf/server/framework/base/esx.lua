if Config.Framework.Active == Framework.ESX then
    function GetPlayerFrameworkIdentifier(source)
        return GetPlayerHandler(source).identifier
    end

    function GetPlayerHandler(source)
        return SharedObject.GetPlayerFromId(source)
    end

    function GetPlayerCharacterName(source)
        local player = SharedObject.GetPlayerFromId(source)
        local playerName = string.format("%s %s", player.get('firstName'), player.get('lastName'))

        return playerName
    end

    function GetPlayerMoney(source, cashType)
        local playerHandler = GetPlayerHandler(source)
        cashType = cashType or CashType.CASH

        if cashType == CashType.CASH then
            return playerHandler.getMoney()
        end

        if cashType == CashType.BANK then
            return playerHandler.getAccount("bank").money
        end

        return 0
    end

    function AddPlayerMoney(source, cashType, money)
        local playerHandler = GetPlayerHandler(source)
        cashType = cashType or CashType.CASH

        if cashType == CashType.CASH then
            playerHandler.addMoney(money)
        end

        if cashType == CashType.BANK then
            playerHandler.addAccountMoney("bank", money)
        end
    end

    function RemovePlayerMoney(source, cashType, money)
        local playerHandler = GetPlayerHandler(source)
        cashType = cashType or CashType.CASH

        if cashType == CashType.CASH then
            playerHandler.removeMoney(money)
        end

        if cashType == CashType.BANK then
            playerHandler.removeAccountMoney("bank", money)
        end
    end

    function GetPlayerRealName(source)
        local playerHandler = GetPlayerHandler(source)
        local name = nil

        return playerHandler.getName()
    end
end
