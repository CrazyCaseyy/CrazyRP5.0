if Config.InventorySystem == Inventory.QS then
    local resourceName = InventoryResourceNames[Inventory.QS]

    function RemovePlayerItem(source, itemName, count)
        exports[resourceName]:RemoveItem(source, itemName, count)
    end

    function AddPlayerItem(source, itemName, count)
        exports[resourceName]:AddItem(source, itemName, count)
    end

    function CanPlayerCarryItem(source, itemName, count)
        return exports[resourceName]:CanCarryItem(source, itemName, count)
    end

    function GetItemCount(source, itemName)
        return exports[resourceName]:GetItemTotalAmount(source, itemName)
    end

    SharedObject.RegisterUsableItem = function(itemName, callBack)
        exports[resourceName]:CreateUsableItem(itemName, callBack)
    end
end