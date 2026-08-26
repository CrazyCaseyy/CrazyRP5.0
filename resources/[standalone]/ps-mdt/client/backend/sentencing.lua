local resourceName = tostring(GetCurrentResourceName())

-- Send to Jail
RegisterNUICallback('sendToJail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'MDT is not open' })
        return
    end

    if type(data) ~= 'table' or not data.citizenId or not data.sentence then
        cb({ success = false, message = 'Missing citizen ID or sentence' })
        return
    end

    local result = ps.callback(resourceName .. ':server:sendToJail', data)

    -- The server callback only validates/notifies - it can't reliably
    -- trigger xt-prison's own jailing (police:server:JailPlayer) itself
    -- since that event checks the caller is a cop within 5m of the
    -- target via the *networked* source, which only comes through
    -- correctly via TriggerServerEvent from here, the officer's own
    -- client - not from server-side code. See server/backend/sentencing.lua.
    if result and result.success and result.targetSource then
        TriggerServerEvent('police:server:JailPlayer', result.targetSource, result.sentence)
    end

    cb(result or { success = false, message = 'Failed to send to jail' })
end)

-- Give Citation
RegisterNUICallback('giveCitation', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'MDT is not open' })
        return
    end

    if type(data) ~= 'table' or not data.citizenId then
        cb({ success = false, message = 'Missing citizen ID' })
        return
    end

    local result = ps.callback(resourceName .. ':server:giveCitation', data)
    cb(result or { success = false, message = 'Failed to give citation' })
end)
