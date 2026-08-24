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

Config.Reputation = {
    MaxLevel = 10,

    -- XP earned per completed "job unit" - one bus/taxi fare, one tow
    -- drop, one trucker delivery, one full garbage shift. Scaled per job so
    -- roughly equal PLAYTIME (not task count) is needed to level up in
    -- every job, since a garbage shift takes far longer than one fare.
    XPPerJob = {
        bus = 20,     -- ~2 min per passenger drop-off
        taxi = 20,    -- ~2 min per fare drop-off
        tow = 30,     -- ~3 min per towed vehicle
        trucker = 30, -- ~3 min per delivery
        garbage = 80, -- ~8 min per full multi-stop shift
    },

    -- XP required to go from level 1 to level 2.
    BaseXP = 150,

    -- Each level after that costs this much MORE than the previous step,
    -- so the grind gets longer the higher a player climbs.
    StepXP = 90,

    -- Payout multiplier granted per level above 1 (level 5 = +32% payout,
    -- level 10 = +72% payout).
    PayoutBonusPerLevel = 0.08,
}
