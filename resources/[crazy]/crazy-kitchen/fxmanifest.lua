fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'crazy-kitchen'
description 'Business crafting stations - job-gated recipe queue + storage per business'
author      'Crazy RP'
version     '1.1.0'

dependencies {
    'ox_lib',
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
    'server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/app.css',
    'html/js/app.js',
    'html/fa-solid.css',
    'html/fa-solid-900.woff2',
    'html/GeomGraphic.woff2',
}
