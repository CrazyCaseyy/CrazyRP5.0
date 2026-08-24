fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-reputation'
author 'crazy-rp'
description 'Reputation tablet UI for civilian jobs'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'scully_emotemenu',
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
    'server/reputation.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/GeomGraphic.woff2',
}
