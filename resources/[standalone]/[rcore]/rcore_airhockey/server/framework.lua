if Config.Framework == 1 then
    ESX = nil
    GetCoreObject(Config.Framework, "es_extended", function(object)
        ESX = object
    end)
end

if Config.Framework == 2 then
    ESX = {}
    GetCoreObject(Config.Framework, "qb-core", function(object)
        QBCore = object
        ESX.GetPlayerFromId = function(source)
            local xPlayer = {}
            local qbPlayer = QBCore.Functions.GetPlayer(source)
            ---------
            if not qbPlayer then
                return nil
            end
            ---------
            xPlayer.identifier = qbPlayer.PlayerData.citizenid
            ---------
            xPlayer.license = qbPlayer.PlayerData.license
            ---------
            xPlayer.playerData = qbPlayer.PlayerData
            ---------
            xPlayer.getName = function()
                if qbPlayer.PlayerData.charinfo and qbPlayer.PlayerData.charinfo.firstname then
                    return qbPlayer.PlayerData.charinfo.firstname
                else
                    return qbPlayer.PlayerData.name
                end
            end
            ---------
            xPlayer.getMoney = function()
                return qbPlayer.Functions.GetMoney("cash")
            end
            ---------
            xPlayer.addMoney = function(money)
                qbPlayer.Functions.AddMoney("cash", money)
            end
            ---------
            xPlayer.addAccountMoney = function(type, money)
                if type == "money" then
                    type = "cash"
                end
                qbPlayer.Functions.AddMoney(type, money)
            end
            ---------
            xPlayer.getAccount = function(type)
                return {
                    money = qbPlayer.Functions.GetMoney(type) or 0
                }
            end
            ---------
            xPlayer.removeAccountMoney = function(type, money)
                qbPlayer.Functions.RemoveMoney(type, money)
            end
            ---------
            xPlayer.removeMoney = function(money)
                qbPlayer.Functions.RemoveMoney("cash", money)
            end
            ---------
            return xPlayer
        end
    end)
end

function GetPlayerRealName(playerId)
    if not ESX then
        return GetPlayerName(playerId)
    end
    local p = ESX.GetPlayerFromId(playerId)
    local name = nil

    if p then
        name = p.getName()
    end

    if not name then
        name = GetPlayerName(playerId)
    end

    return name
end
