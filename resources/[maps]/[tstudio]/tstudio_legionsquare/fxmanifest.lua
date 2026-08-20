fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'tstudio - turbosaif'
description 'Legion Square by TStudio'
version '1.0.0'

this_is_a_map "yes"

dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

client_scripts {
  'client/config.lua',
}

escrow_ignore {
  'stream/vanilla/*.*',
  'stream/ytd/*.ytd',
  'client/config.lua'
}
dependency '/assetpacks'