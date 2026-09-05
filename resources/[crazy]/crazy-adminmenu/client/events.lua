-- Standalone client-side handlers for things triggered from outside the
-- NUI entirely (chat commands, other admin actions) - moved over from
-- qbx_adminmenu's client/main.lua and client/player.lua.

-- Used by the /setmodel command (server/commands.lua).
RegisterNetEvent('qbx_admin:client:setModel', function(skin)
    local model = joaat(skin)
    SetEntityInvincible(cache.ped, true)
    if IsModelInCdimage(model) and IsModelValid(model) then
        lib.requestModel(model)
        SetPlayerModel(cache.playerId, model)
        SetPedRandomComponentVariation(cache.ped, 1)
        SetModelAsNoLongerNeeded(model)
    end
    SetEntityInvincible(cache.ped, false)
end)

-- Fired server-side when an admin uses the Players tab's Kill action
-- (server/server.lua's generalOptions).
RegisterNetEvent('qbx_admin:client:killPlayer', function()
    SetEntityHealth(cache.ped, 0)
end)
