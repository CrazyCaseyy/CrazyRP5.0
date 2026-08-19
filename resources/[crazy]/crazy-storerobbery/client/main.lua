local config = require 'config.shared'
local activePeds = {}
local robbing = false
local robbingStoreId = nil
local cooldownWarned = {}

---@param targetPed number
---@return boolean
local function isThreateningPed(targetPed)
    local weapon = GetSelectedPedWeapon(cache.ped)
    if weapon == `WEAPON_UNARMED` then return false end

    -- Melee weapons can't be "aimed" the way firearms can - being close enough with one out
    -- drawn is treated as a threat instead.
    if GetWeapontypeGroup(weapon) == `GROUP_MELEE` then
        return #(GetEntityCoords(cache.ped) - GetEntityCoords(targetPed)) <= config.threatDistance
    end

    return IsPlayerFreeAimingAtEntity(PlayerId(), targetPed)
end

---@param store table
---@param storeId number
---@return number
local function spawnCashier(store, storeId)
    if activePeds[storeId] and DoesEntityExist(activePeds[storeId]) then
        return activePeds[storeId]
    end

    lib.requestModel(config.pedModel)

    local ped = CreatePed(4, config.pedModel, store.coords.x, store.coords.y, store.coords.z, store.coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDiesInstantlyInWater(ped, false)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(config.pedModel)

    activePeds[storeId] = ped
    return ped
end

---@param storeId number
local function despawnCashier(storeId)
    local ped = activePeds[storeId]
    if ped and DoesEntityExist(ped) then
        DeletePed(ped)
    end
    activePeds[storeId] = nil
end

---@param ped number
local function playScaredAnim(ped)
    lib.requestAnimDict('random@shop_robbery')
    -- The exact same hands-up reaction used in GTA Online's own convenience store robberies
    TaskPlayAnim(ped, 'random@shop_robbery', 'robbery_action_a', 8.0, -8.0, -1, 1, 0, false, false, false)
end

---@param ped number
local function stopScaredAnim(ped)
    if DoesEntityExist(ped) then
        ClearPedTasks(ped)
    end
    RemoveAnimDict('random@shop_robbery')
end

---@param storeId number
---@param ped number
local function startRobbery(storeId, ped)
    if robbing then return end

    local canRob = lib.callback.await('crazy-storerobbery:server:canRob', false, storeId)
    if not canRob then
        if not cooldownWarned[storeId] then
            cooldownWarned[storeId] = true
            exports.qbx_core:Notify(locale('notify.cooldown'), 'error')
        end
        return
    end

    robbing = true
    robbingStoreId = storeId
    playScaredAnim(ped)

    -- Fired at the start, not on success - a dispatch alert that only shows up once the
    -- robbery is already over isn't something police can actually respond to.
    exports['ps-dispatch']:CustomAlert({
        dispatchCode = 'storerobbery', -- matches Config.Blips.storerobbery in ps-dispatch for icon/sound
        message = 'Store Robbery in Progress',
        code = '10-90',
        icon = 'fas fa-cash-register',
        coords = GetEntityCoords(ped),
        jobs = { 'leo' },
    })

    -- Once started, keep going regardless of aim/weapon state - the only thing that cancels it
    -- is leaving the store's radius (handled by the point's onExit below) or the player pressing
    -- the cancel key.
    if lib.progressBar({
        duration = config.duration,
        label = locale('text.robbing'),
        position = 'bottom',
        canCancel = true,
        disable = {
            car = true,
        },
    }) then
        TriggerServerEvent('crazy-storerobbery:server:finishRobbery', storeId)
    else
        TriggerServerEvent('crazy-storerobbery:server:cancelRobbery', storeId)
    end

    robbing = false
    robbingStoreId = nil
    stopScaredAnim(ped)
end

local function setupStores()
    for i, store in ipairs(config.stores) do
        local point = lib.points.new({
            coords = store.coords.xyz,
            distance = 25,
            storeId = i,
        })

        function point:onEnter()
            spawnCashier(store, self.storeId)
        end

        function point:onExit()
            if robbing and robbingStoreId == self.storeId then
                lib.cancelProgress()
            elseif not robbing then
                despawnCashier(self.storeId)
            end
        end

        function point:nearby()
            if robbing then return end

            local ped = activePeds[self.storeId]
            if not ped or not DoesEntityExist(ped) then return end

            if not isThreateningPed(ped) then
                cooldownWarned[self.storeId] = false
                return
            end

            startRobbery(self.storeId, ped)
        end
    end
end

CreateThread(setupStores)
