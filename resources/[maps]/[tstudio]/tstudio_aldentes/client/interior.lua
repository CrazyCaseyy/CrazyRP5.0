-- Simulating an enum for entity sets
local EntitySets = {
    CasinoTableYes = "r8_casino_yes",
    CasinoTableNo = "r8_casino_no"
}

-- Coordinates of the interior (replace with actual coordinates)
local interiorCoords = vector3(-1191.25867, -1402.93933, 7.4126153) -- Example coordinates for Police Station

-- IPL (Interior Prop Load) name (replace with the correct IPL if necessary)
local iplName = "johanni_aldentes_milo_" -- Replace with your IPL if required

-- ####################################################################ü
local selectedEntitySet = EntitySets.CasinoTableNo -- Choose the default entity set 
-- ####################################################################ü

-- Load the IPL if necessary
RequestIpl(iplName)

-- Wait for the IPL to load and activate entity set
Citizen.CreateThread(function()
    -- Wait until the IPL is fully loaded (optional, depends on the interior)
    while not IsIplActive(iplName) do
        Citizen.Wait(0)
    end

    -- Get the interior ID dynamically using coordinates
    local interiorID = GetInteriorAtCoords(interiorCoords.x, interiorCoords.y, interiorCoords.z)

    -- Ensure the interior is valid before proceeding
    if IsValidInterior(interiorID) then
        -- Activate the entity set using enum value

        -- Activate the specific entity set
        ActivateInteriorEntitySet(interiorID, selectedEntitySet)

        -- Refresh the interior to apply changes
        RefreshInterior(interiorID)
    else
        print("Invalid interior ID or the interior could not be found at the provided coordinates.")
    end
end)
