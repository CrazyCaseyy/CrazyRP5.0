fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'tstudio - turbosaif / uNiqx'
description 'Mission Row Police department'
version '1.0.0'

this_is_a_map "yes"

dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

data_file 'GTXD_PARENTING_DATA' 'data/gtxd.meta'

ui_page 'ui/index.html'

files {
    'data/gtxd.meta',
    'ui/index.html',
    'ui/*.js',
    'ui/*.css',
    'ui/*.png',
    'ui/*.jpg',
    'ui/*.svg'
}

shared_scripts {
    'config/*.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'scripts/*.lua'
}

escrow_ignore {
    'config/*.lua',
    'client/*.lua',
    'scripts/*.lua',
    'ui/*.*',
    'stream/vanilla/*.*',
    'stream/general/ytd/*.*',
    'stream/int_main/tstudio_mrpd_int_entryhall_pd_sign.ydr', -- Lobby 3D Sign
    'stream/int_garage/tstudio_mrpd_garage_hallway02_mrpdsign.ydr', -- Garage 3D Sign
    'stream/ext/tstudio_mrpd_ext_building_sign.ydr', -- Building 3D Sign
    'stream/general/ydr/tstudio_mrpd_asset_ext_mrpdsign3d.ydr', -- Exterior 3D Sign
}
dependency '/assetpacks'