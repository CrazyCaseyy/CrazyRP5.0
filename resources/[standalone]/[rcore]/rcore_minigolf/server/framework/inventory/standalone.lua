if Config.InventorySystem == Inventory.STANDALONE then
    function RemovePlayerItem(source, itemName, count)

    end

    function AddPlayerItem(source, itemName, count)

    end

    function CanPlayerCarryItem(source, itemName, count)
        return true
    end

    function GetItemCount(source, itemName)
        return 0
    end

    SharedObject.RegisterUsableItem = function(itemName, callBack)
        RegisterCommand(itemName, function(source)
            callBack(source)
        end)
    end
end
