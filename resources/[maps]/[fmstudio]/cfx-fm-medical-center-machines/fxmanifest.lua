fx_version "cerulean"

game "gta5"

author 'Project X'

description 'FM LS Medical Center Machines'

version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    "config/config.lua",
}

client_scripts {
    "encrypted/client/client.lua",
}

server_scripts {
    "encrypted/server/server.lua",
}

lua54 "yes"

escrow_ignore {
    'config/config.lua',
}

dependency '/assetpacks'
dependency '/assetpacks'