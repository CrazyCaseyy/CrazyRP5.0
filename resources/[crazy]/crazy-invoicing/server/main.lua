local config = require 'config.shared'

local invoices = {}
local nextInvoiceId = 1

---@param jobName string
---@return boolean
local function ensureJobAccount(jobName)
    if GetResourceState('Renewed-Banking') ~= 'started' then return false end
    if exports['Renewed-Banking']:GetJobAccount(jobName) then return true end

    local jobs = exports.qbx_core:GetJobs()
    local label = jobs[jobName] and jobs[jobName].label or jobName

    exports['Renewed-Banking']:CreateJobAccount({ name = jobName, label = label }, 0)
    return true
end

RegisterNetEvent('crazy-invoicing:server:createInvoice', function(targetId, description, amount)
    local source = source
    local sender = exports.qbx_core:GetPlayer(source)
    if not sender then return end

    local job = sender.PlayerData.job
    if not job.onduty or job.type ~= 'business' then
        exports.qbx_core:Notify(source, locale('notify.not_on_duty'), 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        exports.qbx_core:Notify(source, locale('notify.invalid_amount'), 'error')
        return
    end

    if amount > config.maxAmount then
        exports.qbx_core:Notify(source, locale('notify.amount_too_high', config.maxAmount), 'error')
        return
    end

    if type(description) ~= 'string' or description == '' then
        exports.qbx_core:Notify(source, locale('notify.invalid_amount'), 'error')
        return
    end

    -- Self-billing is allowed on purpose, so the flow can be tested solo.
    if not GetPlayerName(targetId) then return end

    amount = math.floor(amount + 0.5)

    local id = nextInvoiceId
    nextInvoiceId += 1

    invoices[id] = {
        sender = source,
        target = targetId,
        description = description,
        amount = amount,
        businessJob = job.name,
        businessLabel = job.label,
    }

    TriggerClientEvent('crazy-invoicing:client:showInvoice', targetId, {
        id = id,
        description = description,
        amount = amount,
        business = job.label,
    })

    exports.qbx_core:Notify(source, locale('notify.invoice_sent'), 'success')
    exports.qbx_core:Notify(targetId, locale('notify.invoice_received', description), 'inform')
end)

RegisterNetEvent('crazy-invoicing:server:payInvoice', function(id, method)
    local source = source
    local invoice = invoices[id]
    if not invoice or invoice.target ~= source then return end

    local customer = exports.qbx_core:GetPlayer(source)
    if not customer then return end

    local moneyType = method == 'card' and 'bank' or 'cash'
    local removed = customer.Functions.RemoveMoney(moneyType, invoice.amount, ('invoice-%s'):format(invoice.businessJob))

    if not removed then
        exports.qbx_core:Notify(source, locale(moneyType == 'bank' and 'notify.not_enough_bank' or 'notify.not_enough_cash'), 'error')
        return
    end

    ensureJobAccount(invoice.businessJob)
    exports['Renewed-Banking']:addAccountMoney(invoice.businessJob, invoice.amount)

    exports.qbx_core:Notify(source, locale('notify.payment_success'), 'success')
    exports.qbx_core:Notify(invoice.sender, locale('notify.payment_received', invoice.amount), 'success')

    TriggerClientEvent('crazy-invoicing:client:closeInvoice', source)
    invoices[id] = nil
end)

AddEventHandler('playerDropped', function()
    local source = source

    for id, invoice in pairs(invoices) do
        if invoice.target == source or invoice.sender == source then
            invoices[id] = nil
        end
    end
end)
