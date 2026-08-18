local chainEquipped = false
local currentChain = nil

local function getCurrentChain()
    local appearance = exports["illenium-appearance"]:getPedAppearance(PlayerPedId())
    if not appearance or not appearance.components then return nil end

    for _, comp in pairs(appearance.components) do
        if comp.component_id == Config.ChainSlot then
            for chainName, chainData in pairs(Config.Chains) do
                if chainData.drawable == comp.drawable and chainData.texture == comp.texture then
                    return chainName
                end
            end
        end
    end

    return nil
end

local function EquipChain(itemName)
    local ped = PlayerPedId()
    local chainData = Config.Chains[itemName]
    if not chainData then return end

    RequestAnimDict('clothingtie')
    while not HasAnimDictLoaded('clothingtie') do Wait(0) end

    if lib.progressBar({
        duration = 3000,
        label = ('Putting on %s'):format(chainData.label or 'chain'),
        useWhileDead = false,
        canCancel = false,
        disable = { car = false, move = false, combat = true },
        anim = { dict = 'clothingtie', clip = 'try_tie_positive_a', flag = 49 }
    }) then
        exports["illenium-appearance"]:setPedComponent(ped, {
            component_id = Config.ChainSlot,
            drawable = chainData.drawable,
            texture = chainData.texture
        })

        chainEquipped = true
        currentChain = itemName
    end
end

local function RemoveChain()
    local ped = PlayerPedId()
    local chainData = Config.Chains[currentChain]

    RequestAnimDict('clothingtie')
    while not HasAnimDictLoaded('clothingtie') do Wait(0) end

    if lib.progressBar({
        duration = 3000,
        label = ('Taking off %s'):format(chainData and chainData.label or 'chain'),
        useWhileDead = false,
        canCancel = false,
        disable = { car = false, move = false, combat = false },
        anim = { dict = 'clothingtie', clip = 'try_tie_positive_a', flag = 49 }
    }) then
        exports["illenium-appearance"]:setPedComponent(ped, {
            component_id = Config.ChainSlot,
            drawable = 0,
            texture = 0
        })

        chainEquipped = false
        currentChain = nil
    end
end

local function DropChain()
    local ped = PlayerPedId()
    exports["illenium-appearance"]:setPedComponent(ped, {
        component_id = Config.ChainSlot,
        drawable = 0,
        texture = 0
    })

    chainEquipped = false
    currentChain = nil
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    local chain = getCurrentChain()
    chainEquipped = (chain ~= nil)
    currentChain = chain
end)

RegisterNetEvent('crazy-chain:useChain', function(itemName)
    if chainEquipped and currentChain == itemName then
        RemoveChain()
    else
        EquipChain(itemName)
    end
end)

RegisterNetEvent('crazy-chain:forceRemoveChain', function()
    if chainEquipped then
        DropChain()
        lib.notify({
            type = 'error',
            description = 'Your chain has been removed because you no longer have it.'
        })
    end
end)

AddEventHandler('ox_inventory:itemCount', function(itemName, totalCount)
    if not chainEquipped or currentChain ~= itemName or totalCount > 0 then return end

    DropChain()
    lib.notify({
        type = 'error',
        description = 'Your chain has been removed because you no longer have it.'
    })
end)

-- Optional: Auto-check chain on resource start
CreateThread(function()
    Wait(1000) -- Give the character system a sec to load
    local chain = getCurrentChain()
    chainEquipped = (chain ~= nil)
    currentChain = chain
end)
