Citizen.CreateThread(function()
    for _, tableData in pairs(TABLES) do
        if tableData.blip then
            local blipHandle = AddBlipForCoord(tableData.pos.x, tableData.pos.y, tableData.pos.z)
            SetBlipSprite(blipHandle, BLIP_CONFIG.sprite)
            SetBlipDisplay(blipHandle, 4)
            SetBlipScale(blipHandle, BLIP_CONFIG.scale)
            SetBlipColour(blipHandle, BLIP_CONFIG.color)
            SetBlipAsShortRange(blipHandle, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(BLIP_CONFIG.label)
            EndTextCommandSetBlipName(blipHandle)
        end
    end
end)