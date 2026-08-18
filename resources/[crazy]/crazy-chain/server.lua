-- Make all chains usable dynamically
for itemName, _ in pairs(Config.Chains) do
    exports.qbx_core:CreateUseableItem(itemName, function(source)
        TriggerClientEvent('crazy-chain:useChain', source, itemName)
    end)
end