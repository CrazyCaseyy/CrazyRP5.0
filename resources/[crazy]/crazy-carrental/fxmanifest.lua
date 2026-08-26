fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'crazy-carrental'
author 'crazy-rp'
description 'Rental ped with ox_lib vehicle + payment menus'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'qbx_vehiclekeys',
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
