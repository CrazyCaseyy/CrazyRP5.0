-- Piggybacks on other resources' own events instead of duplicating their
-- interaction logic: RegisterNetEvent/AddEventHandler both allow multiple
-- handlers per event name, so these fire alongside each resource's own
-- handler for the same event without touching that resource at all.

RegisterNetEvent('qbx_properties:server:exitProperty', function()
    TriggerClientEvent('crazy-tutorial:client:markStep', source, 'exit')
end)

RegisterNetEvent('qbx_properties:server:apartmentSelect', function()
    -- Fires exactly once, right when a brand-new character is placed in
    -- their starting apartment - see crazy-multichar's SpawnSelectedCharacter.
    exports.ox_inventory:AddItem(source, 'tablet', 1)
end)

-- crazy-rules fires this itself (not client-triggered), passing the
-- player explicitly rather than relying on the source global.
AddEventHandler('crazy-rules:server:accepted', function(source)
    TriggerClientEvent('crazy-tutorial:client:markStep', source, 'rules')
end)

-- crazy-carrental fires this itself too. Renting a car also finishes the
-- tutorial - "Enjoy the city!" has no trigger of its own, so it completes
-- alongside "Rent a car".
AddEventHandler('crazy-carrental:server:vehicleRented', function(source)
    TriggerClientEvent('crazy-tutorial:client:markStep', source, 'car')
    TriggerClientEvent('crazy-tutorial:client:markStep', source, 'city')
end)
