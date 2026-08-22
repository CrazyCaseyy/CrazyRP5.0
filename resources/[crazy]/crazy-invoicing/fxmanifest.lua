fx_version 'cerulean'
game 'gta5'

name 'crazy-invoicing'
author 'Crazy RP'
description 'Card reader - any on-duty business employee can charge a nearby customer, who pays cash or card'

ox_lib 'locale'

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'locales/*.json',
    'config/shared.lua',
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
