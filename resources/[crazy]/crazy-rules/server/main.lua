-- Fired for anyone listening (crazy-tutorial piggybacks on this to mark
-- its "Read the rules" step done) rather than coupling directly to it.
RegisterNetEvent('crazy-rules:server:accept', function()
    local source = source
    TriggerEvent('crazy-rules:server:accepted', source)
end)
