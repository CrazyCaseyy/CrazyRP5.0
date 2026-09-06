return {
    DebugPoly = false,
    Freedom = vec4(1840.65, 2586.05, 45.89, 263.19), -- Freedom spawn coords
    RemoveJob = true,          -- Remove player jobs when send to jail

    -- Create Target Zones to Check Time (if XTPrisonJobs is false) --
    -- A list now (one circle zone per counter spot) instead of a single
    -- box, same shape as prisonbreak.lua's HackZones - see
    -- client/modules/prison.lua's createCheckoutLocation/removeCheckoutLocation.
    CheckOut = {
        { coords = vec3(1779.04, 2576.82, 46.39), radius = 0.5 },
        { coords = vec3(1779.04, 2577.63, 46.41), radius = 0.5 },
        { coords = vec3(1779.04, 2578.5, 46.43),  radius = 0.5 },
        { coords = vec3(1779.04, 2579.37, 46.4),  radius = 0.5 },
        { coords = vec3(1779.04, 2580.19, 46.4),  radius = 0.5 },
        { coords = vec3(1779.04, 2581.06, 46.42), radius = 0.5 },
    },

    -- Alert When Entering Prison --
    EnterPrisonAlert  = {
        enable = true,
        header = 'Welcome to Prison, Criminal Scum!',
        content = 'To reduce your time in prison, get a job from the guard in the cells. Get your ass to work and maybe you\'ll learn a thing or two.',
    },

    -- Enter Prison Spawn Location & Emotes (Cells) --
    -- NOTE: entries 6 and 7 below are the exact same coords
    -- (vec4(1626.41, 2463.04, 48.8, 46.96), given twice) - left both in as
    -- given rather than dropped, but worth double-checking that wasn't a
    -- copy-paste duplicate.
    Spawns = {
        { coords = vec4(1622.81, 2481.97, 45.65, 137.96), emote = 'pushup' },
        { coords = vec4(1625.72, 2479.56, 45.65, 142.87), emote = 'weights' },
        { coords = vec4(1628.86, 2477.77, 45.65, 136.08), emote = 'lean' },
        { coords = vec4(1630.93, 2468.39, 45.65, 51.38),  emote = 'pushup' },
        { coords = vec4(1628.51, 2465.65, 45.65, 45.89),  emote = 'weights' },
        { coords = vec4(1626.41, 2463.04, 48.8, 46.96),   emote = 'lean' },
        { coords = vec4(1626.41, 2463.04, 48.8, 46.96),   emote = 'pushup' },
        { coords = vec4(1616.98, 2459.9, 48.8, 319.0),    emote = 'weights' },
        { coords = vec4(1614.25, 2461.9, 48.8, 318.0),    emote = 'lean' },
        { coords = vec4(1611.48, 2464.26, 48.8, 316.57),  emote = 'pushup' },
        { coords = vec4(1608.83, 2466.61, 48.8, 315.47),  emote = 'weights' },
        { coords = vec4(1603.74, 2471.18, 48.8, 318.37),  emote = 'lean' },
        { coords = vec4(1600.97, 2473.49, 48.8, 317.13),  emote = 'pushup' },
        { coords = vec4(1598.55, 2476.12, 48.8, 319.24),  emote = 'weights' },
        { coords = vec4(1595.54, 2478.04, 48.8, 315.98),  emote = 'lean' },
        { coords = vec4(1596.27, 2484.81, 48.8, 232.69),  emote = 'pushup' },
        { coords = vec4(1598.22, 2487.62, 48.8, 228.86),  emote = 'weights' },
        { coords = vec4(1600.39, 2490.41, 45.65, 233.03), emote = 'lean' },
        { coords = vec4(1602.53, 2492.89, 45.65, 226.49), emote = 'pushup' },
        { coords = vec4(1612.31, 2491.43, 45.65, 136.53), emote = 'weights' },
        { coords = vec4(1615.02, 2489.05, 45.65, 136.68), emote = 'lean' },
        { coords = vec4(1617.6, 2486.98, 45.65, 137.46),  emote = 'pushup' },
    },

    -- Canteen Ped --
    CanteenPed = {
        model = 's_m_m_linecook',
        coords = vector4(1739.03, 2587.22, 45.42, 169.36),
        scenario = 'PROP_HUMAN_BBQ',
        mealLength = 2
    },

    -- Prison Doctor --
    PrisonDoctor = {
        model = 's_m_m_doctor_01',
        coords = vector4(1766.45, 2577.03, 46.0, 180.12),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        healLength = 5
    },

    -- Roster Location --
    RosterLocation = {
        coords = vec3(1783.37, 2574.34, 45.88),
        radius = 0.3,
    },

    -- Set Prison Outfits --
    EnablePrisonOutfits = true,
    PrisonOufits = {
        male = {
            accessories = {
                item = 0,
                texture = 0
            },
            mask = {
                item = 0,
                texture = 0
            },
            pants = {
                item = 5,
                texture = 7
            },
            jacket = {
                item = 0,
                texture = 0
            },
            shirt = {
                item = 15,
                texture = 0
            },
            arms = {
                item = 0,
                texture = 0
            },
            shoes = {
                item = 42,
                texture = 2
            },
            bodyArmor = {
                item = 0,
                texture = 0
            },
        },
        female = {
            accessories = {
                item = 0,
                texture = 0
            },
            mask = {
                item = 0,
                texture = 0
            },
            pants = {
                item = 0,
                texture = 0
            },
            jacket = {
                item = 0,
                texture = 0
            },
            shirt = {
                item = 0,
                texture = 0
            },
            arms = {
                item = 0,
                texture = 0
            },
            shoes = {
                item = 0,
                texture = 0
            },
            bodyArmor = {
                item = 0,
                texture = 0
            },
        }
    },

    PlayJailSound = function()
        if GetResourceState('qbx_core') == 'started' then
            lib.load('@qbx_core.modules.lib')

            qbx.loadAudioBank('audiodirectory/xt_prison_sounds')
            qbx.playAudio({
                audioName = 'cell_door',
                audioRef = 'xt_prison'
            })
            ReleaseNamedScriptAudioBank('audiodirectory/xt_prison_sounds')
        else
            local soundId = GetSoundId()
            RequestScriptAudioBank('audiodirectory/xt_prison_sounds', false)
            PlaySoundFrontend(soundId, 'cell_door', 'xt_prison', true)
            ReleaseNamedScriptAudioBank('audiodirectory/xt_prison_sounds')
        end
    end,


    -- Reloads Player's Last Skin When Freed --
    ResetClothing = function()
        -- TriggerEvent('illenium-appearance:client:reloadSkin', true)
    end,

    -- Triggered on Player Heal --
    PlayerHealed = function()
        -- TriggerEvent('qbx_medical:client:playerRevived')
        -- TriggerEvent('hospital:client:Revive')
        -- TriggerEvent('osp_ambulance:partialRevive')
    end,

    -- Trigger Emote --
    Emote = function(emote)
        -- exports.scully_emotemenu:playEmoteByCommand(emote)
        -- exports["rpemotes"]:EmoteCommandStart(emote)
    end,

    -- Trigger Prison Break Dispatch --
    Dispatch = function(coords)
        -- exports['ps-dispatch']:PrisonBreak()
        -- TriggerEvent('police:client:policeAlert', coords, 'Prison Break')

        -- ND Core
        -- exports["ND_MDT"]:createDispatch({
        --             caller = "Boilingbroke Penitentiary",
        --             location = "Sandy Shores",
        --             callDescription = "Prison Break",
        --             coords = vec3(1845.8302, 2585.9011, 45.6726)
        --         })
    end,
}
