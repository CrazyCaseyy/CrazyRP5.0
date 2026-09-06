if Config.InventorySystem == Inventory.QB then
    function RemovePlayerItem(source, itemName, count)
        local player = SharedObject.Functions.GetPlayer(source)

        player.Functions.RemoveItem(itemName, count)
    end

    function AddPlayerItem(source, itemName, count)
        local player = SharedObject.Functions.GetPlayer(source)

        player.Functions.AddItem(itemName, count, false)
    end

    function CanPlayerCarryItem(source, itemName, count)
        local player = SharedObject.Functions.GetPlayer(source)
        local item = SharedObject.Shared.Items[itemName:lower()] or {}

        local ItemInfo = {
            name = itemName,
            count = item.amount or 0,
            label = item.label or "none",
            weight = item.weight or 0,
            usable = item.useable or false,
            rare = false,
            canRemove = false,
        }

        local totalWeight = SharedObject.Player.GetTotalWeight(player.PlayerData.items)
        local MaxWeight = 120000

        if SharedObject.Config.Player.MaxWeight then
            MaxWeight = SharedObject.Config.Player.MaxWeight
        end

        return (totalWeight + (ItemInfo.weight * count)) <= MaxWeight
    end

    function GetItemCount(source, itemName)
        local player = SharedObject.Functions.GetPlayer(source)
        local totalAmount = 0

        for k, v in pairs(player.Functions.GetItemsByName(itemName)) do
            totalAmount = totalAmount + (v.amount or v.count)
        end
        return totalAmount
    end

    SharedObject.RegisterUsableItem = function(itemName, callBack)
        SharedObject.Functions.CreateUseableItem(itemName, callBack)
    end
end