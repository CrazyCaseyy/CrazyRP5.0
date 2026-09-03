Config = {}

-- The lawyer NPC players talk to for their daily task board.
Config.Ped = {
    model = 'a_m_y_business_03',
    coords = vec4(-550.64, -615.13, 34.6, 324.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
}

-- Item handed out per completed task. No functionality yet beyond being an
-- item - more uses for it are a later, separate build.
Config.RewardItem = 'case'

-- How many tasks are picked (from the pool below, no repeats) each day.
Config.TaskCount = 3

-- Pool of possible daily tasks - one per civilian job crazy-reputation
-- tracks. Each day's target for a job is a random amount in [min, max].
Config.JobTargets = {
    bus = { label = 'Bus', min = 5, max = 8 },
    taxi = { label = 'Taxi', min = 5, max = 8 },
    tow = { label = 'Towing', min = 4, max = 6 },
    trucker = { label = 'Trucker', min = 4, max = 6 },
    garbage = { label = 'Garbage', min = 2, max = 3 },
}

-- Where the "Set Waypoint" button on each task card points to - each
-- job's own start/depot location, taken directly from that job
-- resource's own config so it stays consistent if those ever move.
Config.JobLocations = {
    bus = vec3(462.22, -641.15, 28.45),           -- qbx_busjob config/shared.lua location
    taxi = vec3(909.5, -177.35, 74.22),           -- qbx_taxijob config/client.lua locations.main
    tow = vec3(471.39, -1311.03, 29.21),          -- qbx_towjob config/shared.lua locations.main
    trucker = vec3(153.0, -3211.68, 5.91),        -- qbx_truckerjob config/shared.lua locations.main
    garbage = vec3(-313.84, -1522.82, 27.56),     -- qbx_garbagejob config/shared.lua locations.main
}

-- Completed tasks don't pay out on their own - the reward has to be
-- claimed at City Hall (see the "Daily Task Rewards" option added to
-- qbx_cityhall's own menu). This is that same door location, taken from
-- qbx_cityhall config/client.lua peds[1].coords, for the header's
-- "Set Waypoint" button.
Config.CityHallLocation = vec3(-545.32, -611.26, 34.65)
