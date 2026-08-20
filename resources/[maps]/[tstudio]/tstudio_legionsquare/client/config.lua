-- Define IPLs for each setup
local setups = {
    default = {
        'tstudio_legionsquare_ext_amphi_default', 
        -- add more IPLs for the default setup
    },
    band = {
        'tstudio_legionsquare_ext_amphi_band', 
        -- add more IPLs for the band setup
    },
    dj = {
        'tstudio_legionsquare_ext_amphi_dj', 
        -- add more IPLs for the dj setup
    },
    speaker = {
        'tstudio_legionsquare_ext_amphi_speaker', 
        -- add more IPLs for the speaker setup
    },
    cinema = {
        'tstudio_legionsquare_ext_amphi_default', 
        'tstudio_legionsquare_ext_amphi_band', 
        'tstudio_legionsquare_ext_amphi_dj', 
        'tstudio_legionsquare_ext_amphi_speaker', 
    } -- Cinema will remove all IPLs
}

-- Function to remove IPLs from all setups
local function removeAllIpls()
    for _, setupIpls in pairs(setups) do
        for _, ipl in pairs(setupIpls) do
            RemoveIpl(ipl)
        end
    end
end

-- Function to load IPLs for the selected setup
local function loadSetupIpl(setup)
    -- If the chosen setup is "cinema", remove all IPLs
    if setup == "cinema" then
        removeAllIpls()
        print("Cinema setup chosen, all IPLs removed.")
    else
        -- Load IPLs for other setups
        for _, ipl in pairs(setups[setup]) do
            RequestIpl(ipl)
        end
    end
end

-- Setup switching logic
local currentSetup = "default" -- You can change this to "band", "dj", "speaker", or "cinema" to switch between setups.

-- Function to switch setup dynamically
local function switchSetup(newSetup)
    if setups[newSetup] then
        removeAllIpls() -- Always remove all IPLs before switching
        currentSetup = newSetup
        loadSetupIpl(currentSetup)
        print("Switched to setup: " .. currentSetup)
    else
        print("Invalid setup selected! Valid setups: default, band, dj, speaker, cinema.")
    end
end

-- Initialize with default setup
Citizen.CreateThread(function()
    -- Remove any previously loaded IPLs and load the default setup
    removeAllIpls()
    loadSetupIpl(currentSetup)
end)

-- Register a command to change the setup
RegisterCommand("changesetup", function(source, args, rawCommand)
    local newSetup = args[1]
    if newSetup then
        switchSetup(newSetup)
    else
        print("Please specify a valid setup. Usage: /changesetup [default|band|dj|speaker|cinema]")
    end
end, false)
