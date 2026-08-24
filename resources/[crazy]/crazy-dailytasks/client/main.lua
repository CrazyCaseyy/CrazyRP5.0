local isOpen = false

local function openDailyTasks()
    if isOpen then return end

    local tasks = lib.callback.await('crazy-dailytasks:server:getTasks', false)

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', tasks = tasks })
end

local function closeDailyTasks()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeDailyTasks()
    cb(1)
end)

RegisterNetEvent('crazy-dailytasks:client:refreshTasks', function(tasks)
    if not isOpen then return end
    SendNUIMessage({ action = 'update', tasks = tasks })
end)

CreateThread(function()
    local model = joaat(Config.Ped.model)
    if not lib.requestModel(model, 5000) then
        print(('^1[crazy-dailytasks]^7 failed to load ped model %s - lawyer ped was not spawned'):format(Config.Ped.model))
        return
    end

    local coords = Config.Ped.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 then
        print('^1[crazy-dailytasks]^7 CreatePed returned an invalid entity - lawyer ped was not spawned')
        return
    end

    -- Without this, generic ped models like a_m_y_business_03 get a
    -- randomized outfit/appearance each time they're created - this locks
    -- it to the model's single default look so it's the same every time.
    SetPedDefaultComponentVariation(ped)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)

    exports.ox_target:addLocalEntity(ped, {{
        name = 'crazy_dailytasks_lawyer',
        icon = 'fa-solid fa-briefcase',
        label = 'Daily Tasks',
        distance = 1.5,
        onSelect = openDailyTasks,
    }})

    print(('^2[crazy-dailytasks]^7 lawyer ped spawned at %s'):format(tostring(coords)))
end)
