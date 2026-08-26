fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-rules'
author 'crazy-rp'
description '/rules command - accept-to-confirm rules box'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/GeomGraphic.woff2',
}
