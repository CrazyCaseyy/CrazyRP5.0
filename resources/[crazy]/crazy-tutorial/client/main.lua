-- Left-side onboarding checklist shown to a brand-new character right
-- after they finish their initial appearance customization. Started by
-- illenium-appearance's qb-clothes:client:CreateFirstCharacter handler
-- (see [standalone]/illenium-appearance/client/framework/qb/main.lua),
-- which fires crazy-tutorial:client:start once the player submits their
-- appearance (not on cancel).
--
-- Steps are marked done by piggybacking on other resources' own events/
-- hooks rather than duplicating any of their logic here:
--   exit         -> qbx_properties' exitProperty (server/main.lua)
--   rules        -> crazy-rules' accepted event (server/main.lua)
--   inventory    -> below, a passive keybind on the same default key
--                   ox_inventory itself uses (see ox.cfg's inventory:keys),
--                   since ox_inventory doesn't expose an "opened" event -
--                   this is a best-effort proxy for "pressed the key",
--                   not a verified open. Description text is a static
--                   default too - GetControlInstructionalButton (the
--                   native for reading a player's live rebind) is built
--                   for controller glyph icons, not clean keyboard text,
--                   and returned garbage when tried here.
--   tablet       -> crazy-reputation's client:open event (purely
--                   client-side, no server hop needed)
--   phone        -> lb-phone's own AddCheck('openPhone', ...) hook, which
--                   runs on every phone-open attempt regardless of who's
--                   listening; returning true never blocks it.
--   car          -> crazy-carrental's vehicleRented event (server/main.lua)
--   city         -> no trigger of its own; marked done alongside "car"
--                   since "enjoy the city" isn't a real detectable action

local shown = false

local steps = {
    { id = 'exit', label = 'Leave your apartment', done = false },
    {
        id = 'rules',
        label = 'Read the rules',
        description = 'Press T to open chat, then type /rules.',
        done = false
    },
    {
        id = 'inventory',
        label = 'Open your inventory',
        description = 'Press TAB to open your inventory.',
        done = false
    },
    {
        id = 'tablet',
        label = 'Open your tablet',
        description = 'It\'s located in your inventory. Drag it to use it and open the tablet.',
        done = false
    },
    {
        id = 'phone',
        label = 'Open your phone',
        description = 'Press F1 to open your phone.',
        done = false
    },
    { id = 'car', label = 'Rent a car', done = false },
    { id = 'city', label = 'Enjoy the city!', done = false },
}

local function allStepsDone()
    for i = 1, #steps do
        if not steps[i].done then return false end
    end
    return true
end

local function markStep(stepId)
    if not shown then return end
    for i = 1, #steps do
        if steps[i].id == stepId and not steps[i].done then
            steps[i].done = true
            SendNUIMessage({ action = 'markStep', id = stepId })
            if allStepsDone() then
                SetTimeout(3000, function()
                    SendNUIMessage({ action = 'hide' })
                    shown = false
                end)
            end
            break
        end
    end
end

RegisterNetEvent('crazy-tutorial:client:start', function()
    if shown then return end
    shown = true
    for i = 1, #steps do steps[i].done = false end
    SendNUIMessage({ action = 'show', steps = steps })
end)

-- Server-driven steps (qbx_properties/crazy-rules/crazy-carrental actions).
RegisterNetEvent('crazy-tutorial:client:markStep', function(stepId)
    markStep(stepId)
end)

-- Purely client-side: crazy-reputation fires this on the same client the
-- moment the tablet item is used, so there's no need to round-trip
-- through the server for it.
RegisterNetEvent('crazy-reputation:client:open', function()
    markStep('tablet')
end)

-- Passive observer keybind, matching ox_inventory's own primary open key
-- (client.keys[1] there, currently "TAB" per ox.cfg). Doesn't consume or
-- interfere with ox_inventory's own binding - multiple resources can each
-- bind the same physical key independently.
lib.addKeybind({
    name = 'crazy_tutorial_inventory_hint',
    description = 'Tutorial: inventory key pressed',
    defaultKey = 'TAB',
    onPressed = function()
        markStep('inventory')
    end,
})

-- lb-phone's public hook system: every resource's registered "openPhone"
-- check runs on each open attempt, and must all return true for it to
-- proceed. Returning true here never blocks the phone from opening.
exports['lb-phone']:AddCheck('openPhone', function()
    markStep('phone')
    return true
end)

RegisterNUICallback('close', function(_, cb)
    shown = false
    cb('ok')
end)
