fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'crazy-dealership'
author 'crazy-rp'
description 'Vehicle dealership - ox_target catalog, purchase or test drive'
version '1.0.0'

dependencies {
    'qbx_core',
    'qbx_vehicles',
    'qbx_vehiclekeys',
    'ox_lib',
    'ox_target',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}
