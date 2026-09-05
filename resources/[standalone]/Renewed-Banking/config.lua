lib.locale()
Config = {
    -- Framework automatically detected
    -- QB, QBX, and ESX preconfigured edit the framework.lua to add functionality to other frameworks
    renewedMultiJob = false, -- QBCORE ONLY! https://github.com/Renewed-Scripts/qb-phone  
    progressbar = 'rectangle', -- circle or rectangle (Anything other than circle will default to rectangle)
    currency = 'USD', -- USD, EUR, GBP ect.....
    atms = {
        `prop_atm_01`,
        `prop_atm_02`,
        `prop_atm_03`,
        `prop_fleeca_atm`
    },
    peds = {
        [1] = { -- Pacific Standard
            model = 'u_m_m_bankman',
            coords = vector4(241.44, 227.19, 107.29, 170.43),
            createAccounts = true
        },
        [2] = { -- Pink Cage
            model = 'ig_barry',
            coords = vector4(309.35, -278.66, 54.16, 247.62)
        },
        [3] = { -- Legion
            model = 'ig_barry',
            coords = vector4(145.05, -1040.21, 29.37, 252.36)
        },
        [4] = {
            model = 'ig_barry',
            coords = vector4(-351.23, -51.28, 50.04, 341.73)
        },
        [5] = { -- Boulevard Del Perro / Hawic Ave (same coords given for both by request - one physical branch)
            model = 'ig_barry',
            coords = vector4(-1216.33, -333.85, 37.78, 295.82)
        },
        [6] = { -- Great Ocean HWY
            model = 'ig_barry',
            coords = vector4(-2961.57, 478.18, 15.7, 358.98)
        },
        [7] = { -- Route 68
            model = 'ig_barry',
            coords = vector4(1179.77, 2707.99, 38.09, 86.36)
        },
        [8] = { -- paleto
            model = 'u_m_m_bankman',
            coords = vector4(-112.22, 6471.01, 32.63, 134.18),
            createAccounts = true
        }
    }
}
