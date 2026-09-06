if (GetResourceState('qs-inventory') == 'starting' or GetResourceState('qs-inventory') == 'started') then
    Config.EnableQSInventorySupport = true
end

if (GetResourceState('ox_inventory') == 'starting' or GetResourceState('ox_inventory') == 'started') then
    Config.EnableOxInventorySupport = true
end

