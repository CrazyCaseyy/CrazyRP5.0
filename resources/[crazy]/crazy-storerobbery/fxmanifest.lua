fx_version 'cerulean'
game 'gta5'

name 'crazy-storerobbery'
author 'Crazy RP'
description 'Store robbery - threaten the cashier with a weapon to rob the register'

ox_lib 'locale'

dependency 'ps-dispatch'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'locales/*.json',
    'config/shared.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
