-- No more `restricted = config.X` on these - ox_lib's `restricted` is only
-- read once, when lib.addCommand registers the command at resource start,
-- so it could never reflect a tier an owner changes later from the Admins
-- tab without a full resource restart. Every command below checks
-- hasActionPerm (server/permissions.lua) inline instead, which reads the
-- current in-memory tier fresh on every single invocation. The trade-off:
-- ox_lib normally hides a restricted command from a player's /help
-- autocomplete entirely when they lack its permission - these commands
-- exist for everyone now and just reject with a notify if you run one
-- without access, the same as every other permission check in this
-- resource already does.

lib.addCommand('report', {
    help = 'Send Report',
    params = {
        {name = 'report', help = 'Your report message', type = 'string'}
    }
}, function(source, args, raw)
    SendReport(source, string.sub(raw, 8))
end)

lib.addCommand('admin', {
    help = 'Opens Admin Menu',
}, function(source)
    if not hasActionPerm(source, 'menu_open') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:openMenu', source)
end)

lib.addCommand('noclip', {
    help = 'Toggle NoClip',
}, function(source)
    if not hasActionPerm(source, 'self_noclip') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:ToggleNoClip', source)
end)

lib.addCommand('names', {
    help = 'Toggle Player Names',
}, function(source)
    if not hasActionPerm(source, 'self_names') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:names', source)
end)

lib.addCommand('blips', {
    help = 'Toggle Player Blips',
}, function(source)
    if not hasActionPerm(source, 'self_blips') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:blips', source)
end)

lib.addCommand('admincar', {
    help = 'Buy Vehicle',
}, function(source)
    if not hasActionPerm(source, 'vehicle_takeOwnership') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(source), false)
    if vehicle == 0 then
        return exports.qbx_core:Notify(source, 'You have to be in a vehicle, to use this', 'error')
    end

    local vehModel = GetEntityModel(vehicle)

    if not exports.qbx_core:GetVehiclesByHash()[vehModel] then
        return exports.qbx_core:Notify(source, 'Unknown vehicle, please contact your developer to register it.', 'error')
    end

    local playerData = exports.qbx_core:GetPlayer(source).PlayerData
    local vehName, props = lib.callback.await('qbx_admin:client:GetVehicleInfo', source)
    local existingVehicleId = Entity(vehicle).state.vehicleid
    if existingVehicleId then
        local response = lib.callback.await('qbx_admin:client:SaveCarDialog', source)

        if not response then
            return exports.qbx_core:Notify(source, 'Canceled.', 'inform')
        end
        local success, err = exports.qbx_vehicles:SetPlayerVehicleOwner(existingVehicleId, playerData.citizenid)
        if not success then error(err) end
    else
        local vehicleId, err = exports.qbx_vehicles:CreatePlayerVehicle({
            model = vehName,
            citizenid = playerData.citizenid,
            props = props,
        })
        if err then error(err) end
        Entity(vehicle).state:set('vehicleid', vehicleId, true)
    end
    exports.qbx_core:Notify(source, 'This vehicle is now yours.', 'success')
end)

lib.addCommand('setmodel', {
    help = 'Sets your model to the given model',
    params = {
        {name = 'model', help = 'NPC Model', type = 'string'},
        {name = 'id', help = 'Player ID', type = 'number', optional = true},
    }
}, function(source, args)
    if not hasActionPerm(source, 'self_setModel') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    local Target = args.id or source

    if not exports.qbx_core:GetPlayer(Target) then return end

    TriggerClientEvent('qbx_admin:client:setModel', Target, args.model)
end)

lib.addCommand('vec2', {
    help = 'Copy vector2 to clipboard (Admin only)',
}, function(source)
    if not hasActionPerm(source, 'dev_copyCoords') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:copyToClipboard', source, 'coords2')
end)

lib.addCommand('vec3', {
    help = 'Copy vector3 to clipboard (Admin only)',
}, function(source)
    if not hasActionPerm(source, 'dev_copyCoords') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:copyToClipboard', source, 'coords3')
end)

lib.addCommand('vec4', {
    help = 'Copy vector4 to clipboard (Admin only)',
}, function(source)
    if not hasActionPerm(source, 'dev_copyCoords') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:copyToClipboard', source, 'coords4')
end)

lib.addCommand('heading', {
    help = 'Copy heading to clipboard (Admin only)',
}, function(source)
    if not hasActionPerm(source, 'dev_copyCoords') then exports.qbx_core:Notify(source, locale('error.no_perms'), 'error') return end
    if not exports.qbx_core:IsOptin(source) then exports.qbx_core:Notify(source, locale('error.not_optin'), 'error') return end
    TriggerClientEvent('qbx_admin:client:copyToClipboard', source, 'heading')
end)
