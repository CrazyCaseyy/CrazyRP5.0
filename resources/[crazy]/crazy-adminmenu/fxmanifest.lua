fx_version 'cerulean'
game 'gta5'

description 'crazy-adminmenu — server admin dashboard (NUI) plus all admin/dev tooling and commands'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    'client/toggles.lua',
    'client/vectors.lua',
    'client/events.lua',
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/admin.lua',
    'server/commands.lua',
    'server/server.lua',
    'server/permissions.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/*.woff2',
    'locales/*.json',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
