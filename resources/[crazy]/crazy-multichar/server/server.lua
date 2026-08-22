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
