fx_version 'cerulean'
game 'gta5'

name 'crazy-burgershot'
author 'Crazy RP'
description 'Burger Shot job - cook menu items from stocked ingredients and sell them at the register'

ox_lib 'locale'

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
    'crazy-invoicing',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

files {
    'locales/*.json',
    'config/shared.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
