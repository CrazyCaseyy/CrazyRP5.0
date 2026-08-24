fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'crazy-register'
description 'Multi-business register - staff order queue, customer pay terminal, and manager-configurable bundle menus'
author      'Crazy RP'
version     '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/app.css',
    'html/js/app.js',
    'html/sprites/duotone.svg',
    'html/fonts/*.woff2',
}
