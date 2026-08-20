return {
    creatorName = "Hane Maps",
    patches = {
        {
            name = "Fix for Garage & Hane Pillbox",
            requiredMaps = {"tstudio_legionsquare_garage", "hane_data_downtown"},
            fixResource = "tstudio_zpatch_garage_hane_pillbox"
        }, {
            name = "Fix for Legion Square & Hane Pillbox",
            requiredMaps = {"tstudio_legionsquare", "hane_data_downtown"},
            fixResource = "tstudio_zpatch_ls_hane_pillbox"
        }, {
            name = "Fix for Missionrow Park, Legion Square & Hane Pillbox",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_legionsquare", "hane_data_downtown"},
            fixResource = "tstudio_zpatch_mrpark_ls_hane_pillbox"
        }
    }
}
