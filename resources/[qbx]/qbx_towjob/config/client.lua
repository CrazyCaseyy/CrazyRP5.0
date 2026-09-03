return {
    debugPoly = false,
    useTarget = GetConvar('UseTarget', 'false') == 'true',
    vehicles = {
        ["flatbed"] = "Flatbed",
    },
    -- The clipboard NPC at locations.start.
    ped = {
        model = 'csb_trafficwarden',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
}