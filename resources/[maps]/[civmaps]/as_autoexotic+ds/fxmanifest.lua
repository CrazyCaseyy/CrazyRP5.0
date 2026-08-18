fx_version 'cerulean'
games { 'gta5' }

author 'AS MLO - Swarex x Azzox'
description 'AS MLO AutoExotic + Dealership'
version '2.6'
this_is_a_map 'yes'

files {
    "audio/as_autoexotic_game.dat151.rel",
    "audio/as_dealership_interior_game.dat151.rel",
    "audio/as_showroom_game.dat151.rel"
}

data_file "AUDIO_GAMEDATA" "audio/as_autoexotic_game.dat"
data_file "AUDIO_GAMEDATA" "audio/as_dealership_interior_game.dat"
data_file "AUDIO_GAMEDATA" "audio/as_showroom_game.dat"

escrow_ignore {
    'stream/**/*.ytd',
    'stream/**/*.ydd',
    'stream/**/*.ymap'
}

dependency '/assetpacks'