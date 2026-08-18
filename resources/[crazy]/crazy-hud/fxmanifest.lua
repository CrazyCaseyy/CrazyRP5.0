fx_version 'cerulean'
game 'gta5'

description 'Crazy RP HUD'
version '0.1.0'

ox_lib 'locale'

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
    'html/index.html',
    'html/theme-scrubber.js',
    'html/themeConfig.json',
    'html/static/js/*.js',
    'html/static/css/*.css',
    'html/icons/*.svg',
    'html/fonts/*.woff2',
    'html/images/*.png',
    'html/sprites/*.svg',
    'locales/*.json',
    'config/client.lua',
    'config/shared.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
