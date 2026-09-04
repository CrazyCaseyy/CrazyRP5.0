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

-- The roll happens as soon as they click "Open" (below), but the actual
-- payout is held here until the reel's animation actually finishes and
-- the client calls back to claim it - see the 'reveal' NUI callback in
-- client/main.lua. That's the whole point of this table: it's what stops
-- the item/cash showing up before the case has visually finished
-- opening.
local pendingRewards = {} -- [citizenid] = { reward = <Config.Rewards entry>, amount = number?, count = number? }

-- How many of an item-type reward to actually hand out - the entry's own
-- `count` if it has one (non-stackable equipment pins this to 1),
-- otherwise the rarity's default from Config.RarityItemAmount.
local function itemCountFor(reward)
    return reward.count or Config.RarityItemAmount[reward.rarity] or 1
end

local function grantPending(player, pending)
    if pending.reward.type == 'cash' then
        player.Functions.AddMoney('cash', pending.amount, 'case-opening-reward')
    else
        exports.ox_inventory:AddItem(player.PlayerData.source, pending.reward.item, pending.count or 1)
    end
end

-- Called when the player clicks "Open" in the NUI. Removing the case and
-- rolling the reward happen here, together, so a case can't be
-- duplicated or opened for free by retrying the client side - but the
-- reward itself isn't handed over yet.
lib.callback.register('crazy-caseopening:server:roll', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    if pendingRewards[citizenid] then
        return { error = 'already_opening' }
    end

    local removed = exports.ox_inventory:RemoveItem(source, Config.ItemName, 1)
    if not removed then
        return { error = 'no_case' }
    end

    local reward = weightedRoll()
    local amount = reward.type == 'cash' and math.random(reward.amount[1], reward.amount[2]) or nil
    local count = reward.type == 'item' and itemCountFor(reward) or nil
    pendingRewards[citizenid] = { reward = reward, amount = amount, count = count }

    return { rewardId = reward.id, amount = amount, count = count }
end)

-- Called once the reel actually lands (client/main.lua's 'reveal' NUI
-- callback) - this is what actually puts the reward in their pocket.
RegisterNetEvent('crazy-caseopening:server:claim', function()
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local pending = pendingRewards[citizenid]
    if not pending then return end
    pendingRewards[citizenid] = nil

    grantPending(player, pending)
end)

-- Safety net: if they disconnect between rolling and the reel actually
-- landing (a few seconds), grant the reward anyway rather than the case
-- just being eaten for nothing.
AddEventHandler('playerDropped', function()
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local pending = pendingRewards[citizenid]
    if not pending then return end
    pendingRewards[citizenid] = nil

    grantPending(player, pending)
end)

exports.qbx_core:CreateUseableItem(Config.ItemName, function(source)
    TriggerClientEvent('crazy-caseopening:client:open', source)
end)
