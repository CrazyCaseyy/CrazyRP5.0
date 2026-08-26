fx_version 'cerulean'
games { 'gta5' }

author 'AS MLO - Swarex'
description 'AS MLO Premium Deluxe Motorsport'
this_is_a_map 'yes'
version '1.2'

files { 
        'audio/as_garpdm_game.dat151.rel',
        'audio/as_luxpdm_game.dat151.rel'
}

data_file 'AUDIO_GAMEDATA' 'audio/as_garpdm_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/as_luxpdm_game.dat'

escrow_ignore {
    'stream/**/*.ytd',
    'stream/**/*.ytyp'
}
dependency '/assetpacks'