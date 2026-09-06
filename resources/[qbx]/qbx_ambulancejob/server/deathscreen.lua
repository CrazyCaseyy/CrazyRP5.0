-- Server-authoritative half of the ox_target "Help Them Up" interaction
-- (client/deathscreen.lua) - the client-side canInteract check only drives
-- whether the option is shown, this is what actually gates the revive so
-- a modified client can't just fire this event on an ALIVE/DEAD target.
RegisterNetEvent('hospital:server:HelpPlayerUp', function(targetId)
    if GetInvokingResource() then return end
    local src = source
    targetId = tonumber(targetId)
    if not targetId or targetId == src then return end

    local target = Player(targetId)
    if not target or target.state['qbx_medical:deathState'] ~= 2 then return end

    -- Not a full medical revive (that's what EMS's firstaid-based
    -- hospital:server:RevivePlayer is for) - getting helped up just gets
    -- them back on their feet at 10 HP, still critical. The actual health
    -- value is set client-side (client/deathscreen.lua's HelpedUp handler).
    TriggerClientEvent('hospital:client:HelpedUp', targetId)
    exports.qbx_core:Notify(src, 'You helped them back to their feet.', 'success')
    exports.qbx_core:Notify(targetId, 'Someone helped you back to your feet.', 'success')
end)
