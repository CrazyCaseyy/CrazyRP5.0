local config = require 'config.shared'

local menuByName = {}
for i = 1, #config.menu do
    menuByName[config.menu[i].name] = config.menu[i]
end

local stockByName = {}
for i = 1, #config.stock do
    stockByName[config.stock[i].name] = config.stock[i]
end

CreateThread(function()
    while GetResourceState('Renewed-Banking') ~= 'started' do
        Wait(500)
    end

    exports['Renewed-Banking']:CreateJobAccount({ name = config.job, label = 'BurgerShot' }, 0)
end)

---@param source number
---@return boolean
local function isOnDuty(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    return player.PlayerData.job.name == config.job and player.PlayerData.job.onduty
end

RegisterNetEvent('crazy-burgershot:server:buyStock', function(stockName)
    local source = source
    local stock = stockByName[stockName]
    if not stock then return end
    if not isOnDuty(source) then
        exports.qbx_core:Notify(source, locale('notify.not_on_duty'), 'error')
        return
    end

    local account = exports['Renewed-Banking']:GetJobAccount(config.job)
    if not account or account.amount < stock.cost then
        exports.qbx_core:Notify(source, locale('notify.not_enough_stock_funds'), 'error')
        return
    end

    if not exports['Renewed-Banking']:removeAccountMoney(config.job, stock.cost) then
        exports.qbx_core:Notify(source, locale('notify.not_enough_stock_funds'), 'error')
        return
    end

    exports.ox_inventory:AddItem(source, stock.name, stock.amount)
    exports.qbx_core:Notify(source, locale('notify.stock_bought', stock.amount, stock.label), 'success')
end)

RegisterNetEvent('crazy-burgershot:server:sellItem', function(itemName)
    local source = source
    local item = menuByName[itemName]
    if not item then return end
    if not isOnDuty(source) then
        exports.qbx_core:Notify(source, locale('notify.not_on_duty'), 'error')
        return
    end

    if exports.ox_inventory:GetItemCount(source, item.name) < 1 then
        exports.qbx_core:Notify(source, locale('notify.no_item_to_sell'), 'error')
        return
    end

    local removed = exports.ox_inventory:RemoveItem(source, item.name, 1)
    if not removed then
        exports.qbx_core:Notify(source, locale('notify.no_item_to_sell'), 'error')
        return
    end

    local tip = math.floor(item.price * config.tipPercent + 0.5)
    local businessCut = item.price - tip

    exports['Renewed-Banking']:addAccountMoney(config.job, businessCut)

    if tip > 0 then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            player.Functions.AddMoney('cash', tip, 'burgershot-tip')
        end
    end

    exports.qbx_core:Notify(source, locale('notify.item_sold', item.label, item.price, tip), 'success')
end)
