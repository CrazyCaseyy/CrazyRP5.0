fx_version 'cerulean'
game 'gta5'

description 'crazy-adminmenu — NUI dashboard front-end for qbx_adminmenu'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/*.woff2',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
