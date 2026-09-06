if Config.InventorySystem == Inventory.ORIGEN then
    local resourceName = InventoryResourceNames[Inventory.ORIGEN]

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

    -- seems like it is using default stuff for register.
    --SharedObject.RegisterUsableItem = function(itemName, callBack)
    --end
end