fx_version 'bodacious'
game 'gta5'

author 'TStudio - uNiqx'
description 'Modern Fleeca Banks'
version '1.0'

this_is_a_map 'yes'


dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

files {
    'stream/vanilla/*/*.*',
}

escrow_ignore {
    'stream/vanilla/*.*',
    'stream/loc*/*.*',
    'stream/ytd/*.ytd',
    'fix_other_maps/*/*.*',
}
dependency '/assetpacks'