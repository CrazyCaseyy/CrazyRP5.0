fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'crazy-minigames'
author 'crazy-rp'
description 'Shared home for custom minigames (handcuffs, and future additions), one NUI page shared between them'
version '1.0.0'

dependencies {
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
}

-- Each minigame gets its own file here - add new ones to both lists
-- below as they're built.
client_scripts {
    'client/handcuffs.lua',
}

server_scripts {
    'server/handcuffs.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/GeomGraphic.woff2',
}
