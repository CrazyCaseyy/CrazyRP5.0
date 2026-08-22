Config = {}

-- Item name used to open the tablet (see server/main.lua for the actual
-- ox_inventory item registration).
Config.ItemName = 'tablet'

-- Only these job keys (qbx_core/shared/jobs.lua) show up on the tablet.
-- Everything else qbx_core has (LEO, EMS, all the business/mechanic shops,
-- etc.) is left off for now.
Config.IncludedJobs = {
    bus = true,
    garbage = true,
    taxi = true,
    tow = true,
    trucker = true,
}
