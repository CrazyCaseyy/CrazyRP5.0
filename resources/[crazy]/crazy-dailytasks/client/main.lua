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

RegisterNUICallback('setWaypoint', function(data, cb)
    local coords = Config.JobLocations[data.job]
    if coords then
        SetNewWaypoint(coords.x, coords.y)
        exports.qbx_core:Notify('Waypoint set.', 'success')
    end
    cb(1)
end)

-- Claimed right here at the lawyer ped, not elsewhere - the button lives
-- inside this same panel.
RegisterNUICallback('claimRewards', function(_, cb)
    local result = lib.callback.await('crazy-dailytasks:server:claimRewards', false)
    if not result then return cb(1) end

    if result.claimed > 0 then
        exports.qbx_core:Notify(('Claimed %d task reward%s.'):format(result.claimed, result.claimed == 1 and '' or 's'), 'success')
    else
        exports.qbx_core:Notify('No completed task rewards to claim right now.', 'inform')
    end

    SendNUIMessage({ action = 'update', tasks = result.tasks })
    cb(1)
end)

RegisterNetEvent('crazy-dailytasks:client:refreshTasks', function(tasks)
    if not isOpen then return end
    SendNUIMessage({ action = 'update', tasks = tasks })
end)

RegisterCommand('tasks', function()
    openDailyTasks()
end, false)

local pedSpawned = false

-- On a fresh server restart, this resource's client scripts start at the
-- exact same moment as the player's whole session/world is also booting -
-- every resource is streaming assets at once, so model loading here can
-- time out (and lib.requestModel throws, not returns false, on timeout -
-- silently killing this whole thread with no retry). A manual
-- `restart crazy-dailytasks` later works fine because by then the world
-- is already idle. Rather than race that boot storm, wait for the player
-- to actually be loaded in - QBCore:Client:OnPlayerLoaded, which only
-- fires once they're spawned and past character select - so this runs
-- well clear of it, same as a manual restart would.
local function SpawnLawyerPed()
    if pedSpawned then return end
    pedSpawned = true

    local model = joaat(Config.Ped.model)
    local ok = pcall(lib.requestModel, model, 10000)
    if not ok or not HasModelLoaded(model) then
        print(('^1[crazy-dailytasks]^7 failed to load ped model %s - lawyer ped was not spawned'):format(Config.Ped.model))
        pedSpawned = false
        return
    end

    local coords = Config.Ped.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 then
        print('^1[crazy-dailytasks]^7 CreatePed returned an invalid entity - lawyer ped was not spawned')
        pedSpawned = false
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
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', SpawnLawyerPed)

-- Covers a client that's already loaded in by the time this resource
-- (re)starts - e.g. a manual `restart crazy-dailytasks` - since
-- OnPlayerLoaded won't fire again for them on its own.
if LocalPlayer.state.isLoggedIn then
    SpawnLawyerPed()
end
