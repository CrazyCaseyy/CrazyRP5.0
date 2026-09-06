RegisterCommand('showarmwrestling', function(source)
    if source == 0 then
        print("---- ARM WRESTLING PROXIMITY ----")
        for idx, tableData in pairs(TABLES) do
            print("Table #" .. idx .. '(' .. tableData.model .. ')')

            if tableData.players then
                for posId, serverId in pairs(tableData.players) do
                    print("\t-> " .. posId .. ' - '.. serverId)
                end
            end
        end
        
        print("=================================")
    end
end, true)

