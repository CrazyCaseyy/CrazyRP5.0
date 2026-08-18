shared_script "@ReaperV4/imports/bypass.lua"
shared_script "@ReaperV4/imports/bypass_s.lua"
shared_script "@ReaperV4/imports/bypass_c.lua"
lua54 "yes" -- needed for Reaper



fx_version 'cerulean'
game 'gta5'

author 'CrazyCasey'
description 'Multi-chain wearable accessory script for FiveM'
version '1.0.0'

-- Dependencies (optional but recommended to state)
dependencies {
    'ox_inventory',
    'qbx_core',
    'ox_lib'
}

-- Shared config file
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

-- Client scripts
client_scripts {
    'client.lua'
}

-- Server scripts
server_scripts {
    'server.lua'
}
