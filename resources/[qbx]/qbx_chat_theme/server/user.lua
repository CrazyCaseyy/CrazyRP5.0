-- Second, independent enforcement point for the same "no plain text, only
-- '/commands'" rule as server/message-filter.lua - this hook runs BEFORE
-- the chatMessage event does (confirmed against the actual chat resource
-- source: routeMessage builds outMessage as
-- {color, multiline, args = {message} or {author, message}, mode}, runs
-- every registered hook, and only fires TriggerEvent('chatMessage', ...)
-- afterward), so cancelling here is a step earlier/more reliable than
-- relying on chatMessage + CancelEvent alone.
-- Shared with server/message-filter.lua (same resource, same Lua state) so
-- that if BOTH this hook and the chatMessage handler end up seeing the same
-- submission, the command only actually gets relayed/executed once.
RelayedChatMessages = RelayedChatMessages or {}

exports.chat:registerMessageHook(function(source, outMessage, hookRef)
    local message = outMessage.args and outMessage.args[#outMessage.args]

    if message and message ~= '' and message:sub(1, 1) ~= '/' then
        print(('^5[qbx_chat_theme]^7 hook intercepted plain message from %s: "%s"'):format(tostring(source), message))
        hookRef.cancel()
        RelayedChatMessages[source] = message
        TriggerClientEvent('qbx_chat_theme:client:runAsCommand', source, message)
        return
    end

    hookRef.updateMessage({
        templateId = 'user',
    })
end)
