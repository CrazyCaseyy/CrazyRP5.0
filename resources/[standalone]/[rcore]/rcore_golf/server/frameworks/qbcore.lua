if Config.Framework == nil or Config.Framework == 0 then
    if GetResourceState('qb-core') == 'starting' or GetResourceState('qb-core') == 'started' then
        Config.Framework = 2
    end
end

if Config.SocietySystem == 0 then
    if GetResourceState('qb-bossmenu') == 'starting' or GetResourceState('qb-bossmenu') == 'started' then
        Config.SocietySystem = 2
    end

    if GetResourceState('qb-management') == 'starting' or GetResourceState('qb-management') == 'started' then
        Config.SocietySystem = 3
    end

end

if Config.Framework == 2 then
    if Config.FrameworkTriggers['notify'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['notify'])) == 'qbcore' then
        Config.FrameworkTriggers['notify'] = 'QBCore:Notify'
    end

    if Config.FrameworkTriggers['load'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['load'])) == 'qbcore' then
        Config.FrameworkTriggers['load'] = 'QBCore:GetObject'
    end

    if Config.FrameworkTriggers['resourceName'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['resourceName'])) == 'qbcore' then
        Config.FrameworkTriggers['resourceName'] = 'qb-core'
    end
end

CreateThread(function()
    local version = GetResourceMetadata('qb-banking', 'version', 0)
    if version and version >= "2.0.0" then Config.SocietySystem = 4 end

    if Config.Framework == 2 then
        local QBCore = Citizen.Await(GetSharedObjectSafe())

        ShowNotification = function(serverId, msg)
            TriggerClientEvent(Config.FrameworkTriggers['notify'], serverId, msg)
        end

        GetCharacterName = function(serverId)
            local Player = QBCore.Functions.GetPlayer(serverId)
            local PlayerInfo = Player.PlayerData.charinfo
            return PlayerInfo.firstname.." "..PlayerInfo.lastname
        end


        GetCharacterIdentifier = function(serverId)
            local Player = QBCore.Functions.GetPlayer(serverId)
            return Player.PlayerData.citizenid
        end

        PlayerHasItem = function(serverId, amount)
            if Config.EnableQSInventorySupport then
                local result = exports['qs-inventory']:GetItemTotalAmount(serverId, Config.GolfClubItem)
                return result and result >= amount
            elseif Config.EnableOxInventorySupport then
                return exports.ox_inventory:GetItemCount(serverId, Config.GolfClubItem) >= amount
            else
                return QBCore.Functions.HasItem(serverId, Config.GolfClubItem, amount)
            end
        end

        PlayerHasMoney = function(serverId, amount)
            amount = amount or 0
            return GetPlayerMoney(serverId) >= amount
        end

        GetPlayerMoney = function(serverId)
            return QBCore.Functions.GetPlayer(serverId).PlayerData.money.cash
        end

        PlayerTakeMoney = function(serverId, amount, reason)
            amount = amount or 0
            if PlayerHasMoney(serverId, amount) then
                return QBCore.Functions.GetPlayer(serverId).Functions.RemoveMoney('cash', amount, reason)
            end
            return false
        end

        PlayerGiveMoney = function(serverId, amount, reason)
            if amount then
                QBCore.Functions.GetPlayer(serverId).Functions.AddMoney('cash', amount, reason)
            end
        end

        SetVehicleUnlocked = GiveCaddyVehicleKeys

        local qbHud = LoadResourceFile('qb-hud', 'client.lua')
        if qbHud ~= nil then
            if not string.match(qbHud, "rcoreGolfShowRadar") then
                qbHud = qbHud:gsub("DisplayRadar%(Menu%.isOutMapChecked%)", "DisplayRadar(Menu.isOutMapChecked or rcoreGolfShowRadar)")
                qbHud = qbHud:gsub("SetRadarZoom%(", "SetRadarZoom(rcoreGolfMapZoom or ")
                qbHud = qbHud .. "\n\nrcoreGolfShowRadar = false\nrcoreGolfMapZoom = nil\nAddEventHandler('rcore_golf:setShowRadar', function(v) rcoreGolfShowRadar = v end)\nAddEventHandler('rcore_golf:setMapZoom', function(v) rcoreGolfMapZoom = v end)"
                SaveResourceFile('qb-hud', 'client.lua', qbHud, -1)
                print('^1===================== WARNING =====================^7')
                print('^7We recommend that you restart qb-hud so that no errors occur')
                print('^1===================== WARNING ==========================^7')
            end
        end


        AddSocietyMoney = function(amount)
            if not Config.SocietyEnabled then return end

            if Config.SocietySystem == 2 then
                TriggerEvent('qb-bossmenu:server:addAccountMoney', Config.SocietyName, amount)
            elseif Config.SocietySystem == 3 then
                return exports['qb-management']:AddMoney(Config.SocietyName, amount)
            elseif Config.SocietySystem == 4 then
                exports['qb-banking']:AddMoney(Config.SocietyName, amount)
            end
        end

        AddWagerCommissionToSociety = function(amount)
            if not Config.SocietyEnabled or not Config.HasWagerCommission then return end

            if Config.SocietySystem == 2 then
                TriggerEvent('qb-bossmenu:server:addAccountMoney', Config.SocietyName, amount)
            elseif Config.SocietySystem == 3 then
                return exports['qb-management']:AddMoney(Config.SocietyName, amount)
            elseif Config.SocietySystem == 4 then
                exports['qb-banking']:AddMoney(Config.SocietyName, amount)
            end
        end

    end
end)

function GiveCaddyVehicleKeys(serverId, vehicleId)
    if type(vehicleId) ~= 'number' then return end

    CreateThread(function()
        local ent = 0
        for _ = 1, 30 do
            ent = NetworkGetEntityFromNetworkId(vehicleId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then
                break
            end
            Wait(100)
        end

        if not ent or ent == 0 or not DoesEntityExist(ent) then return end
        if GetEntityModel(ent) ~= joaat(Config.CaddyVehicleName) then return end

        local ped = GetPlayerPed(serverId)
        if not ped or ped == 0 then return end
        if #(GetEntityCoords(ent) - GetEntityCoords(ped)) > 150.0 then return end

        local vin = Entity(ent).state.VIN or exports.prp_vehicle:AssignTempVIN(ent)
        if not vin then return end

        Entity(ent).state:set('Locked', false, true)
        SetVehicleDoorsLocked(ent, 1)
        exports.prp_vehicle:GiveKeys(serverId, vin)
    end)
end

SetVehicleUnlocked = GiveCaddyVehicleKeys

RegisterNetEvent('rcore_golf:giveCaddyKeys', function(netId)
    GiveCaddyVehicleKeys(source, netId)
end)
