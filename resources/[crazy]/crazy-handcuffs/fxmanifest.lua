fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-handcuffs'
author 'crazy-rp'
description 'Bottom-of-screen timing minigame, exported for other resources to gate handcuffing on'
version '1.0.0'

dependencies {
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
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
