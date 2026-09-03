Config = Config or {}

Config.Emergency = {
    requireDutyCheck = false,	-- if true, when a mechanic is online, the repair button won't show
                                -- if false, the repair option will always be available
    Jobs = {
        -- DO NOT DO THIS -- ["police"] = 0, 1, 2, 3 - This is not how this works
        -- The grade is that grade and above, so if its 2 then its everything from 2 and above
        ["police"] = 0, -- Job and Job Grade
        ["ambulance"] = 0,
    },

    LockEmergency = false,  -- Enable this to lock make only "Emergency" (Class 18) vehicles to be used with the bench

    Locations = {
      --{ coords = vec4(448.06, -970.64, 25.71, 177.94), prop = false, }, -- MRPD UNDERGROUND PARKING
        { coords = vec4(449.29, -970.18, 25.67, 41.97), prop = false, }, -- MRPD
        { coords = vec4(-854.21, -1227.02, 6.89, 321.06), prop = true, }, -- Hospital
        { coords = vec4(-826.75, -1239.00, 13.13, 140.00), prop = true, }, -- Hospital Roof

    },

    CosmeticTable = { 			-- This controls what will appear in the emergency mech bench, "false" to hide it
        ["Repair" ] = true,
        ["Paints"] = true,
        ["Horn"] = true,
        ["Hood"] = true,
        ["Exhaust"] = true,
        ["RollCage"] = true,
        ["Roof"] = true,
        ["Spoiler"] = true,
        ["Seats"] = true,
        ["PlateHolder"] = true,
        ["VanityPlate"] = true,
        ["CustomPlate"] = true,
        ["Skirts"] = true,
        ["RightFender"] = true,
        ["LeftFender"] = true,
        ["Liverys"] = true,
        ["OldLiverys"] = true,
        ["RoofLiverys"] = true,
        ["Grille"] = true,
        ["FrontBumper"] = true,
        ["BackBumper"] = true,
        ["TrimA"] = true,
        ["TrimB"] = true,
        ["Trunk"] = true,
        ["EngineBlock"] = true,
        ["Filter"] = true,
        ["Struts"] = true,
        ["Hydraulics"] = true,
        ["ArchCovers"] = true,
        ["FuelTank"] = true,
        ["Aerials"] = true,
        ["Extras"] = true,
        ["Ornaments"] = true,
        ["DashBoard"] = true,
        ["Dials"] = true,
        ["DoorSpeakers"] = true,
        ["SteeringWheels"] = true,
        ["ShifterLeavers"] = true,
        ["Plaques"] = true,
        ["Speakers"] = true,
        ["WindowTints"] = true,
        ["Rims"] = true,
        ["Lightbar"] = true,
    },

    PreformaceTable = {
        ["Engine"] = true,
        ["Brakes"] = true,
        ["Suspension"] = true,
        ["Transmission"] = true,
        ["Armour"] = false,
        ["Turbo"] = false,
        ["Harness"] = true,
    }

}

Config.ManualRepairs = { -- Player vehicle repair config
    ManualRepairCost = math.random(15000,20000), 					-- Set this to a high amount to get people to talk to mechanics rather than use automated systems
    ManualRepairCostBased = true, 				-- Set this to true if you want the cost to ALWAYS be the amount set at "ManualRepairCost"
                                                -- Set this to false if you want it to "ManualRepairCost" to be the max and cost is calculated by damage

    ManualRepairBased = false, 					-- Set this to true if you want to set the repair cost to be based on Shared Vehicle info costs(overrides the cost setting above)
    ManualRepairPercent = 5,					-- Set this to the percent of the vehicle price (Only works if ManualRepairBased is true)
                                                -- Default is 5% because $200,000 would be $10,000 max to repair by this system
                                                -- 5% of a $10,000 car would be $500

    repairEngine = true, 						-- Set this to true if automated repairs also repair engine (not just body)
    repairExtras = false, 						-- Set this to true for automated repairs to also repair extra damages (if mechanicjob is available and repairEngine is true)

    requireDutyCheck = false, 					-- if set to true, the repair bench will only be usable if there are no mechanics in the server ON DUTY

    repairAnimate = true,						-- Better than staring at a progress bar, "damaged" parts will be removed and replaced. Making it look more authentic
    repairSpeed = 90000, 						-- The time between each task while using repairAnimate. 1500 Seems to be a reasonable time for it
}