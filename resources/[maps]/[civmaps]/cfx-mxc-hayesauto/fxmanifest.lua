fx_version "cerulean"
game "gta5"
lua54 "yes"

author 'MXC'
description 'HAYESAUTO'
version '1.0.0'


data_file 'DLC_ITYP_REQUEST' 'bkr_biker_dlc_int_02.ytyp'
data_file 'DLC_ITYP_REQUEST' 'xm3_dlc_int_03_xm3.ytyp'
data_file 'DLC_ITYP_REQUEST' 'int_services.ytyp'
data_file 'DLC_ITYP_REQUEST' 'int_medical.ytyp'


data_file 'TIMECYCLEMOD_FILE' 'mxc_timecycle_list_01.xml'

files {
    'mxc_timecycle_list_01.xml',
}

escrow_ignore {
    'stream/[multi-location]/limbo-mirrorpark/*.ydr',
    'stream/[multi-location]/limbo-paleto/*.ydr',
    'stream/[multi-location]/limbo-southls/*.ydr',
    'stream/[eup]/mp_m_freemode_01_male_heist^lowr_006_r.ydd',
    'stream/[eup]/mp_m_freemode_01_male_heist^jbib_013_u.ydd',
}

-- PREMIUM ONLY

data_file 'AUDIO_GAMEDATA' '[audio]/mxc_hayes_game.dat'

file {
    '[audio]/mxc_hayes_game.dat151.rel',
}


dependency '/assetpacks'