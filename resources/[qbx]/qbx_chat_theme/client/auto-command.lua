-- Runs plain (non-'/') chat input as a command on THIS client, matching
-- server/message-filter.lua. Executing it client-side (rather than the
-- server just calling it directly) matters: ExecuteCommand here correctly
-- attributes this player as the command's source when it RPCs back to any
-- server-registered command, identical to actually typing the '/' version.
RegisterNetEvent('qbx_chat_theme:client:runAsCommand', function(message)
    ExecuteCommand(message)
end)
