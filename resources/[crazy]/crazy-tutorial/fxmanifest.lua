fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-tutorial'
author 'crazy-rp'
description 'New player onboarding checklist'
version '1.0.0'

dependencies {
    'qbx_core',
    'qbx_properties',
    'illenium-appearance',
    'crazy-reputation',
    'crazy-carrental',
    'crazy-rules',
    'ox_lib',
    'ox_inventory',
    'lb-phone',
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
