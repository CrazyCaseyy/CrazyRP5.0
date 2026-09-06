if Config.Framework.Active == Framework.STANDALONE then
    function GetPlayerFrameworkIdentifier(source)
        return GetPlayerIdentifierType(source, Config.StandaloneSettings.DefaultIdentifierType)
    end

    function GetPlayerHandler(source)
        return nil
    end

    function GetPlayerCharacterName(source)
        return GetPlayerName(source)
    end

    function GetPlayerMoney(source, cashType)
        return 2147483647
    end

    function AddPlayerMoney(source, cashType, money)

    end

    function RemovePlayerMoney(source, cashType, money)

    end

    function GetPlayerRealName(source)
        return GetPlayerName(source)
    end
end

