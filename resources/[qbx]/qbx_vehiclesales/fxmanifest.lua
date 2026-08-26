fx_version 'cerulean'
game 'gta5'

description 'Vehicle dealership - ox_target catalog, purchase or test drive'
version '2.0.0'

dependencies {
    'qbx_core',
    'qbx_vehiclekeys',
    'ox_lib',
    'ox_target',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'config/client.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
