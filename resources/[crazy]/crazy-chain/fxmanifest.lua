lua54 'yes'

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
