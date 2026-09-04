local showCoords = false
local vehicleDev = false
local showLaser = false
local vehicleTypes = {'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports', 'Super', 'Motorcycles', 'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats', 'Helicopters', 'Planes', 'Service', 'Emergency', 'Military', 'Commercial', 'Trains', 'Open Wheel'}
local options = {
    function() CopyToClipboard('coords2') lib.showMenu('qbx_adminmenu_dev_menu', MenuIndexes.qbx_adminmenu_dev_menu) end,
    function() CopyToClipboard('coords3') lib.showMenu('qbx_adminmenu_dev_menu', MenuIndexes.qbx_adminmenu_dev_menu) end,
    function() CopyToClipboard('coords4') lib.showMenu('qbx_adminmenu_dev_menu', MenuIndexes.qbx_adminmenu_dev_menu) end,
    function() CopyToClipboard('heading') lib.showMenu('qbx_adminmenu_dev_menu', MenuIndexes.qbx_adminmenu_dev_menu) end,
    function()
        showCoords = not showCoords
        while showCoords do
            local coords, heading = GetEntityCoords(cache.ped), GetEntityHeading(cache.ped)

            qbx.drawText2d({
                text = ('~o~vector4~w~(%s, %s, %s, %s)'):format(qbx.math.round(coords.x, 2), qbx.math.round(coords.y, 2), qbx.math.round(coords.z, 2), qbx.math.round(heading, 2)),
                coords = vec2(1.0, 0.5),
                scale = 0.5,
                font = 6
            })

            Wait(0)
        end
    end,
    function()
        vehicleDev = not vehicleDev
        while vehicleDev do
            if cache.vehicle then
                local clutch, gear, rpm, temperature = GetVehicleClutch(cache.vehicle), GetVehicleCurrentGear(cache.vehicle), GetVehicleCurrentRpm(cache.vehicle), GetVehicleEngineTemperature(cache.vehicle)
                local oil, angle, body, class = GetVehicleOilLevel(cache.vehicle), GetVehicleSteeringAngle(cache.vehicle), GetVehicleBodyHealth(cache.vehicle), vehicleTypes[GetVehicleClass(cache.vehicle)]
                local dirt, maxSpeed, netId, hash = GetVehicleDirtLevel(cache.vehicle), GetVehicleEstimatedMaxSpeed(cache.vehicle), VehToNet(cache.vehicle), GetEntityModel(cache.vehicle)
                local name = GetLabelText(GetDisplayNameFromVehicleModel(hash))
                qbx.drawText2d({
                    text = ('~o~Clutch: ~w~ %s | ~o~Gear: ~w~ %s | ~o~Rpm: ~w~ %s | ~o~Temperature: ~w~ %s'):format(qbx.math.round(clutch, 4), gear, qbx.math.round(rpm, 4), temperature),
                    coords = vec2(1.0, 0.575),
                    scale = 0.45,
                    font = 6
                })
                qbx.drawText2d({
                    text = ('~o~Oil: ~w~ %s | ~o~Steering Angle: ~w~ %s | ~o~Body: ~w~ %s | ~o~Class: ~w~ %s'):format(qbx.math.round(oil, 4), qbx.math.round(angle, 4), qbx.math.round(body, 4), class),
                    coords = vec2(1.0, 0.600),
                    scale = 0.45,
                    font = 6
                })
                qbx.drawText2d({
                    text = ('~o~Dirt: ~w~ %s | ~o~Est Max Speed: ~w~ %s | ~o~Net ID: ~w~ %s | ~o~Hash: ~w~ %s'):format(qbx.math.round(dirt, 4), qbx.math.round(maxSpeed, 4) * 3.6, netId, hash),
                    coords = vec2(1.0, 0.625),
                    scale = 0.45,
                    font = 6
                })
                qbx.drawText2d({
                    text = ('~o~Vehicle Name: ~w~ %s'):format(name),
                    coords = vec2(1.0, 0.650),
                    scale = 0.45,
                    font = 6
                })
                Wait(0)
            else
                Wait(800)
            end
        end
    end,
    function()
        showLaser = not showLaser
        while showLaser do
            -- ox_lib's raycast already yields internally (GetShapeTestResult
            -- is polled in a Wait(0) loop until it resolves), so this while
            -- loop never spins without yielding even though there's no
            -- explicit Wait(0) of our own below.
            local hit, _, endCoords = lib.raycast.fromCamera(511, 4, 150.0)
            local camCoords = GetFinalRenderedCamCoord()

            DrawLine(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 255, 30, 30, 220)
            DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.06, 0.06, 0.06, 255, 30, 30, 200, false, false, 2, false, nil, nil, false)

            local x, y, z = qbx.math.round(endCoords.x, 2), qbx.math.round(endCoords.y, 2), qbx.math.round(endCoords.z, 2)
            -- coords.x is always 1.0 here, same as every other qbx.drawText2d
            -- call in this file - qbx.drawText2d's width/height default to
            -- 1.0 and it offsets by half of that, so 1.0 is what actually
            -- lands centered; 0.5 (the naive "half the screen" guess) would
            -- render off to the left instead.
            qbx.drawText2d({
                text = ('~r~LASER~s~  vec3(%s, %s, %s)  ~s~[E] Copy'):format(x, y, z),
                coords = vec2(1.0, 0.85),
                scale = 0.4,
                font = 6,
                enableDropShadow = true,
            })

            if hit and IsControlJustReleased(0, 38) then
                lib.setClipboard(('vec3(%s, %s, %s)'):format(x, y, z))
                exports.qbx_core:Notify('Copied to clipboard', 'success')
            end
        end
    end,
}

-- Exported so other UIs (crazy-adminmenu) can trigger the same
-- toggles this file already owns (showCoords/vehicleDev/showLaser are
-- local to this closure and have no other command/event wrapper).
exports('ToggleCoordsDisplay', function() options[5]() end)
exports('ToggleVehicleInfoDisplay', function() options[6]() end)
exports('ToggleLaser', function() options[7]() end)
exports('GetDevToggleState', function()
    return { coords = showCoords, vehicleInfo = vehicleDev, laser = showLaser }
end)

lib.registerMenu({
    id = 'qbx_adminmenu_dev_menu',
    title = locale('title.dev_menu'),
    position = 'top-right',
    onClose = function(keyPressed)
        CloseMenu(false, keyPressed, 'qbx_adminmenu_main_menu')
    end,
    onSelected = function(selected)
        MenuIndexes.qbx_adminmenu_dev_menu = selected
    end,
    options = {
        {label = locale('dev_options.label1'), description = locale('dev_options.desc1'), icon = 'fas fa-compass'},
        {label = locale('dev_options.label2'), description = locale('dev_options.desc2'), icon = 'fas fa-compass'},
        {label = locale('dev_options.label3'), description = locale('dev_options.desc3'), icon = 'fas fa-compass'},
        {label = locale('dev_options.label4'), description = locale('dev_options.desc4'), icon = 'fas fa-compass'},
        {label = locale('dev_options.label5'), description = locale('dev_options.desc5'), icon = 'fas fa-compass-drafting', close = false},
        {label = locale('dev_options.label6'), description = locale('dev_options.desc6'), icon = 'fas fa-car-side', close = false}
    }
}, function(selected)
    options[selected]()
end)
