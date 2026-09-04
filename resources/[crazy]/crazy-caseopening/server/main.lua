-- Weighted random pick from Config.Rewards. Weights don't need to sum to
-- any particular number - normalized against their own total here.
local function weightedRoll()
    local total = 0
    for _, r in ipairs(Config.Rewards) do
        total += r.weight
    end

    local roll = math.random() * total
    local cumulative = 0
    for _, r in ipairs(Config.Rewards) do
        cumulative += r.weight
        if roll <= cumulative then return r end
    end

    return Config.Rewards[#Config.Rewards]
end

-- Called by the client once its NUI is up and ready to spin (see
-- client/main.lua). Removing the case and rolling the reward happen
-- here, together, so a case can't be duplicated or opened for free by
-- retrying the client side.
lib.callback.register('crazy-caseopening:server:open', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local removed = exports.ox_inventory:RemoveItem(source, Config.ItemName, 1)
    if not removed then
        return { error = 'no_case' }
    end

    local reward = weightedRoll()

    if reward.type == 'cash' then
        local amount = math.random(reward.amount[1], reward.amount[2])
        player.Functions.AddMoney('cash', amount, 'case-opening-reward')
        return { rewardId = reward.id, amount = amount }
    end

    exports.ox_inventory:AddItem(source, reward.item, 1)
    return { rewardId = reward.id }
end)

-- The item itself isn't consumed by ox_inventory automatically (it has
-- no `consume` field set) - crazy-caseopening:server:open above is what
-- actually removes it, once the client's ready to show the result.
exports.qbx_core:CreateUseableItem(Config.ItemName, function(source)
    TriggerClientEvent('crazy-caseopening:client:open', source)
end)
