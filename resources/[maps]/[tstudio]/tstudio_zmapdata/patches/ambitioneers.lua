return {
    creatorName = "Ambitioneers Maps",
    patches = {
        {
            name = "Fix for Water XML of Pearls Resort & Ambitioneers Roxwood",
            requiredMaps = {"tstudio_pearls_resort", "amb-roxwood-map"},
            fixResource = "tstudio_zpatch_pearls_ambitioneers_roxwood_water"
        },
        {
            name = 'Fix for Mission Row Park & Ambitioneers Rags&Riches',
            requiredMaps = { 'amb-lslive-main-patches', 'tstudio_missionrow_park' },
            fixResource = 'tstudio_zpatch_rr_amb_mrpark',
        },
        {
            name = 'Fix for Legion Square & Mission Row Park & Ambitioneers Rags&Riches',
            requiredMaps = { 'amb-lslive-main-patches', 'tstudio_legionsquare', 'tstudio_missionrow_park' },
            fixResource = 'tstudio_zpatch_rr_amb_ls_mrpark',
        },
        {
            name = 'Fix for Legion Square & Ambitioneers Rags&Riches',
            requiredMaps = { 'amb-lslive-main-patches', 'tstudio_legionsquare' },
            fixResource = 'tstudio_zpatch_rr_amb_ls',
        }
    }
}
