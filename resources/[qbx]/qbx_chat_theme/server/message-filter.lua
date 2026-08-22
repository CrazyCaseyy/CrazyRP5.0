-- Real '/commands' never reach this handler at all - the chat NUI executes
-- them client-side directly (ExecuteCommand), bypassing this server event
-- entirely. Everything that DOES land here is plain typed text with no
-- leading '/', which used to broadcast as an ordinary chat message.
--
-- Instead of just dropping it, relay it back to that same player's client
-- to run through ExecuteCommand exactly as if they'd typed the '/' version
-- themselves - "e dance" now plays the emote the same way "/e dance"
-- always did, and plain text that isn't a real command just quietly does
-- nothing (FiveM's command system already no-ops on unknown commands),
-- instead of showing up as unwanted chat spam.
AddEventHandler('chatMessage', function(src, _name, message)
    if not message or message == '' then return end
    if message:sub(1, 1) == '/' then return end -- shouldn't happen, but never our job to touch it

    CancelEvent()

    -- server/user.lua's message hook runs before this event and may have
    -- already relayed this exact message - if so, skip re-running it so
    -- the command doesn't fire twice.
    RelayedChatMessages = RelayedChatMessages or {}
    if RelayedChatMessages[src] == message then
        RelayedChatMessages[src] = nil
        return
    end

    print(('^5[qbx_chat_theme]^7 chatMessage intercepted plain message from %s: "%s" - cancelling broadcast, running as command'):format(tostring(src), message))
    TriggerClientEvent('qbx_chat_theme:client:runAsCommand', src, message)
end)
