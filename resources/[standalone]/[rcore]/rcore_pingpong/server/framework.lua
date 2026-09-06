function IsResourceRunning(res)
    local s = GetResourceState(res)
    return s == "starting" or s == "started"
end

local function CleanMoney(m)
    m = tonumber(m)
    if not m or m <= 0 then
        return 0
    end
    return math.floor(m)
end

if IsResourceRunning(Config.QBCoreResourceName) then
    -- QBCore implementation
    QBCore = exports[Config.QBCoreResourceName]:GetCoreObject()
    function GetQbCorePlayer(playerId)
        return QBCore.Functions.GetPlayer(playerId)
    end
    function GetPlayerMoney(playerId)
        local player = GetQbCorePlayer(playerId)
        if player then
            if Config.BettingInventoryName then
                local totalAmount = 0
                for k, v in pairs(player.Functions.GetItemsByName(Config.BettingInventoryName) or {}) do
                    totalAmount = totalAmount + (v.amount or v.count or 0)
                end
                return totalAmount
            end
            return player.Functions.GetMoney("cash") or 0
        end
        return 0
    end
    function GivePlayerMoney(playerId, money)
        money = CleanMoney(money)
        if money <= 0 then
            return
        end
        local player = GetQbCorePlayer(playerId)
        if player then
            if Config.BettingInventoryName then
                player.Functions.AddItem(Config.BettingInventoryName, money)
                return
            end
            player.Functions.AddMoney("cash", money)
        end
    end
    function RemovePlayerMoney(playerId, money)
        money = CleanMoney(money)
        if money <= 0 then
            return
        end
        local player = GetQbCorePlayer(playerId)
        if player then
            if Config.BettingInventoryName then
                player.Functions.RemoveItem(Config.BettingInventoryName, money)
                return
            end
            player.Functions.RemoveMoney("cash", money)
        end
    end
    function GetPlayerRealName(playerId)
        local player = GetQbCorePlayer(playerId)
        if player then
            if player.PlayerData.charinfo and player.PlayerData.charinfo.firstname then
                return player.PlayerData.charinfo.firstname
            else
                return player.PlayerData.name
            end
        end
        return GetPlayerName(playerId)
    end
elseif IsResourceRunning(Config.ESXResourceName) then
    -- ESX implementation
    ESX = exports[Config.ESXResourceName]:getSharedObject()
    function GetEsxPlayer(playerId)
        return ESX.GetPlayerFromId(playerId)
    end
    function GetPlayerMoney(playerId)
        local player = GetEsxPlayer(playerId)
        if player then
            if Config.BettingInventoryName then
                local xItem = player.getInventoryItem(Config.BettingInventoryName)
                if xItem then
                    return xItem.count or xItem.amount or 0
                end
            end
            return player.getMoney() or 0
        end
        return 0
    end
    function GivePlayerMoney(playerId, money)
        money = CleanMoney(money)
        if money <= 0 then
            return
        end
        local player = GetEsxPlayer(playerId)
        if player then
            if Config.BettingInventoryName then
                player.addInventoryItem(Config.BettingInventoryName, money)
                return
            end
            player.addMoney(money)
        end
    end
    function RemovePlayerMoney(playerId, money)
        money = CleanMoney(money)
        if money <= 0 then
            return
        end
        local player = GetEsxPlayer(playerId)
        if player then
            if Config.BettingInventoryName then
                player.removeInventoryItem(Config.BettingInventoryName, money)
                return
            end
            player.removeMoney(money)
        end
    end
    function GetPlayerRealName(playerId)
        local player = GetEsxPlayer(playerId)
        if player then
            return player.getName()
        end
        return GetPlayerName(playerId)
    end
else
    -- Custom implementation
    function GetPlayerMoney(playerId)
        -- This function returns the amount of money a player has.
        -- You can implement custom logic here to support different frameworks or inventory items.
        return 0
    end

    function GivePlayerMoney(playerId, money)
        -- This function gives money to a player.
        -- You can implement custom logic here to support different frameworks or inventory items.
    end

    function RemovePlayerMoney(playerId, money)
        -- This function removes money from a player.
        -- You can implement custom logic here to support different frameworks or inventory items.
    end

    function GetPlayerRealName(playerId)
        -- This function returns the real name of a player.
        -- You can implement custom logic here to support different frameworks.
        return GetPlayerName(playerId)
    end
end
