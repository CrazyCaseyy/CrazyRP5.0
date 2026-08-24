fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-dailytasks'
author 'crazy-rp'
description 'Lawyer NPC daily task board'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
    'crazy-reputation',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/GeomGraphic.woff2',
}
