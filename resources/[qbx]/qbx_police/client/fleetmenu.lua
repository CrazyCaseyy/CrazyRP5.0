-- /fleetvehicle - lets a police boss browse the whole fleet (qbx_garages'
-- 'policefleet' garage, server/fleet.lua) and assign/reassign/unassign
-- vehicles to specific officers, instead of needing the /assignfleet and
-- /unassignfleet console-style commands. All the actual data lives in
-- qbx_garages (player_vehicles, police_fleet_assignments) - this is purely
-- the UI, talking to it over lib.callback the same way any other resource
-- would.

---@param vehicle { id: integer, plate: string, model: string, assignedCitizenid: string?, assignedName: string? }
function openOfficerPicker(vehicle)
    local officers = lib.callback.await('qbx_police:server:getOnlinePolice', false)
    if not officers or #officers == 0 then
        exports.qbx_core:Notify('No officers online.', 'error')
        return
    end

    local options = {}
    for i = 1, #officers do
        local officer = officers[i]
        options[i] = {
            title = officer.name,
            description = officer.grade,
            icon = 'user',
            onSelect = function()
                local success, result = lib.callback.await('qbx_garages:server:assignFleetVehicle', false, vehicle.id, officer.id)
                if success then
                    exports.qbx_core:Notify(('%s assigned to %s.'):format(vehicle.plate, result), 'success')
                else
                    exports.qbx_core:Notify(result, 'error')
                end
                openFleetMenu()
            end,
        }
    end

    lib.registerContext({
        id = 'fleetOfficerPicker',
        title = ('Assign %s'):format(vehicle.plate),
        menu = 'fleetVehicleActions',
        options = options,
    })
    lib.showContext('fleetOfficerPicker')
end

---@param vehicle { id: integer, plate: string, model: string, assignedCitizenid: string?, assignedName: string? }
function openFleetVehicleActions(vehicle)
    local options = {}

    if vehicle.assignedCitizenid then
        options[#options + 1] = {
            title = 'Unassign',
            icon = 'user-xmark',
            description = ('Currently assigned to %s'):format(vehicle.assignedName),
            onSelect = function()
                local success, err = lib.callback.await('qbx_garages:server:unassignFleetVehicle', false, vehicle.id)
                if success then
                    exports.qbx_core:Notify(('%s unassigned.'):format(vehicle.plate), 'success')
                else
                    exports.qbx_core:Notify(err, 'error')
                end
                openFleetMenu()
            end,
        }
    end

    options[#options + 1] = {
        title = vehicle.assignedCitizenid and 'Reassign To...' or 'Assign To...',
        icon = 'user-plus',
        arrow = true,
        onSelect = function()
            openOfficerPicker(vehicle)
        end,
    }

    options[#options + 1] = {
        title = 'Delete',
        icon = 'trash',
        description = 'Removes it from the fleet permanently. Must be parked first.',
        onSelect = function()
            local confirmed = lib.alertDialog({
                header = 'Delete Fleet Vehicle',
                content = ('Permanently remove %s from the fleet? This cannot be undone.'):format(vehicle.plate),
                centered = true,
                cancel = true,
            })
            if confirmed ~= 'confirm' then
                return openFleetVehicleActions(vehicle)
            end

            local success, result = lib.callback.await('qbx_garages:server:deleteFleetVehicle', false, vehicle.id)
            if success then
                exports.qbx_core:Notify(('%s removed from the fleet.'):format(result), 'success')
            else
                exports.qbx_core:Notify(result, 'error')
            end
            openFleetMenu()
        end,
    }

    lib.registerContext({
        id = 'fleetVehicleActions',
        title = vehicle.plate,
        menu = 'fleetVehicleMenu',
        options = options,
    })
    lib.showContext('fleetVehicleActions')
end

-- Prompts for a model name and adds it to the fleet. A separate function
-- (rather than inline in openFleetMenu's option) since the "no vehicles yet"
-- empty state below also needs to trigger it.
function openAddFleetVehicle()
    local input = lib.inputDialog('Add Fleet Vehicle', {
        { type = 'input', label = 'Vehicle Model', description = 'Spawn code, e.g. police, police2, police3', required = true },
    })
    if not input then
        return openFleetMenu()
    end

    local success, result = lib.callback.await('qbx_garages:server:addFleetVehicle', false, input[1])
    if success then
        exports.qbx_core:Notify(('%s (%s) added to the fleet.'):format(input[1], result), 'success')
    else
        exports.qbx_core:Notify(result, 'error')
    end
    openFleetMenu()
end

function openFleetMenu()
    local roster = lib.callback.await('qbx_garages:server:getFleetRoster', false) or {}

    local vehicleList = exports.qbx_core:GetVehiclesByName()
    local options = {}

    options[#options + 1] = {
        title = 'Add Vehicle',
        icon = 'plus',
        iconColor = '#4caf50',
        onSelect = openAddFleetVehicle,
    }

    for i = 1, #roster do
        local vehicle = roster[i]
        local vehicleData = vehicleList[vehicle.model]
        local label = vehicleData and ('%s %s'):format(vehicleData.brand, vehicleData.name) or vehicle.model

        options[#options + 1] = {
            title = label,
            description = vehicle.assignedName and ('%s · Assigned to %s'):format(vehicle.plate, vehicle.assignedName)
                or ('%s · Unassigned'):format(vehicle.plate),
            icon = vehicle.assignedCitizenid and 'user-check' or 'car-side',
            arrow = true,
            onSelect = function()
                openFleetVehicleActions(vehicle)
            end,
        }
    end

    lib.registerContext({
        id = 'fleetVehicleMenu',
        title = 'Police Fleet',
        options = options,
    })
    lib.showContext('fleetVehicleMenu')
end

-- lib.addCommand is server-only in ox_lib (imports/addCommand/server.lua) -
-- this needs to run client-side (to open a local ox_lib context menu), so
-- it's the plain native RegisterCommand instead.
RegisterCommand('fleetvehicle', function()
    if QBX.PlayerData.job.name ~= 'police' or not QBX.PlayerData.job.isboss then
        exports.qbx_core:Notify('You need to be a police boss to do that.', 'error')
        return
    end

    openFleetMenu()
end, false)
