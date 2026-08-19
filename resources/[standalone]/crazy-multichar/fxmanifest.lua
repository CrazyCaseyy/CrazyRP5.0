fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-multichar'
author 'you'
description 'Custom external multicharacter select screen for QBX Core — ox_lib-themed, 3 character slots, live ped preview with a full character info panel'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/GeomGraphic.woff2'
}
