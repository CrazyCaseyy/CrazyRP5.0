local showIDs = false
local showUntil = 0
local maxDistance = 20
local toggleKey = 303

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, toggleKey) then
            showIDs = true
            showUntil = GetGameTimer() + 10000
        end
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local dist = #(GetGameplayCamCoords() - vec3(x, y, z))
    local scale = 0.35 / dist
    if scale > 0.6 then scale = 0.6 end
    if onScreen then
        SetTextScale(0.7, 0.7)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if showIDs then
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) and NetworkIsPlayerActive(player) then
                    local coords = GetEntityCoords(ped)
                    local distance = #(myCoords - coords)
                    if distance <= maxDistance then
                        if HasEntityClearLosToEntity(myPed, ped, 17) then
                            DrawText3D(coords.x, coords.y, coords.z + 1.0, tostring(GetPlayerServerId(player)))
                        end
                    end
                end
            end
            if GetGameTimer() > showUntil then
                showIDs = false
            end
        end
    end
end)
