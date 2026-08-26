fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

version '1.0.2'
author 'Flame Studios - https://flame-studios.tebex.io/'
description 'Flame Studios - FIB Headquarters Interior'

files {
    'audio/fs_fbi1.dat151.rel',
    'audio/fs_fbi2.dat151.rel',
    'audio/fs_fbi3.dat151.rel',

}
-- Audio files
data_file 'AUDIO_GAMEDATA' 'audio/fs_fbi1.dat'
data_file 'AUDIO_GAMEDATA' 'audio/fs_fbi2.dat'
data_file 'AUDIO_GAMEDATA' 'audio/fs_fbi3.dat'

--Scenario files
file 'sp_manifest.ymt'
data_file 'SCENARIO_POINTS_OVERRIDE_FILE' 'stream/sp_manifest.ymt'
dependency '/assetpacks'