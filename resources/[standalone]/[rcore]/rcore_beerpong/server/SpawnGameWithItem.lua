if Config.Framework == "1" or Config.Framework == "2" or Config.ox_inv then
    if Config.ox_inv then
        exports("cups", function(event, item, inventory, slot, data)
            local source = inventory.id
            TriggerClientEvent("rcore_beerpong:startEditGame", source)
        end)

        RegisterNetEvent(TriggerName("RemoveCupSet"), function()
            exports.ox_inventory:RemoveItem(source, "cups", 1)
        end)
    else
        ESX.RegisterUsableItem(Config.ItemName, function(source)
            TriggerClientEvent("rcore_beerpong:startEditGame", source)
        end)

        RegisterNetEvent(TriggerName("RemoveCupSet"), function()
            local xPlayer = ESX.GetPlayerFromId(source)
            xPlayer.removeInventoryItem(Config.ItemName, 1)
        end)
    end
end