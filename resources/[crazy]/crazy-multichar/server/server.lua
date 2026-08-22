-- Feeds the character-select preview a citizen's actual saved appearance
-- (illenium-appearance's `playerskins` table) so the select screen can show
-- what the character really looks like, not just their base gender model.
-- Reads the table directly rather than going through illenium-appearance's
-- own server callback, since that callback only resolves the CURRENTLY
-- LOADED player's citizenid (Framework.GetPlayerID(source)) — useless here,
-- since none of these characters are loaded yet. The `playerskins` schema
-- (citizenid, model, skin, active) is illenium-appearance's own stable table,
-- queried the same way its own Framework.GetAppearance() does.

lib.callback.register('crazy-multichar:server:getAppearance', function(_, citizenId)
    if not citizenId then return nil end

    local row = MySQL.scalar.await('SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1', { citizenId })
    if not row then return nil end

    local ok, decoded = pcall(json.decode, row)
    if not ok then return nil end
    return decoded
end)

-- The spawn-location preview camera hovers over real map coordinates near
-- other players, so the player picking a spawn is moved into their own
-- routing bucket for it (their own server id, guaranteed unique) - the
-- static world is unaffected by buckets, but no other bucket-0 player/ped/
-- vehicle will be visible to them, and they won't be visible to anyone
-- else either. qbx_core's own SetPlayerBucket export does the actual
-- native call and keeps its own bucket bookkeeping in sync.
lib.callback.register('crazy-multichar:server:enterSoloBucket', function(source)
    exports.qbx_core:SetPlayerBucket(source, source)
    return true
end)

lib.callback.register('crazy-multichar:server:leaveSoloBucket', function(source)
    exports.qbx_core:SetPlayerBucket(source, 0)
    return true
end)
