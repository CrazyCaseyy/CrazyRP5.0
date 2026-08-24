fx_version 'bodacious'
game 'gta5'

author 'FM'
description 'LS MEDICAL CENTER'
version '1.0'

this_is_a_map 'yes'

data_file 'AUDIO_GAMEDATA' 'audio/fm_medical_center_interior_game.dat'
data_file "SCENARIO_POINTS_OVERRIDE_PSO_FILE" "alta.ymt"
data_file 'TIMECYCLEMOD_FILE' 'fm_timecycle_list_hospital.xml'

files {
    'fm_timecycle_list_hospital.xml',
    'audio/fm_medical_center_interior_game.dat151.rel',

}

escrow_ignore {
    'stream/[editable]/fm_hsp_e_signs.ydr',
    'stream/[editable]/fm_hsp_logos_01.ydr',

  }


dependency '/assetpacks'