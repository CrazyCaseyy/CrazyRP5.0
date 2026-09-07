fx_version 'cerulean'
game 'gta5'

name 'qbx_policejob'
description 'Police system for Qbox'
repository 'https://github.com/Qbox-project/qbx_policejob'
version '1.0.0'

ox_lib 'locale'

-- client/fleetmenu.lua + server/fleetmenu.lua (/fleetvehicle) talk to
-- qbx_garages' fleet callbacks directly - not a hard requirement for
-- anything else in this resource, but ensures it's actually up first.
dependency 'qbx_garages'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/vue.min.js',
    'html/script.js',
    'html/fingerprint.png',
    'html/main.css',
    'config/client.lua',
    'config/shared.lua',
    'locales/*.json'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'