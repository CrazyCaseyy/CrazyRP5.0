fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'


data_file 'DLC_ITYP_REQUEST' 'stream/prompt_prison_escapeprops.ytyp'

data_file 'AUDIO_GAMEDATA' 'audio/prompt_entrance_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_block_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_dining_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_block3_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_block1_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_cells_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_workshop_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_newinmates_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_admin_game.dat' -- dat151

files {
  'audio/prompt_entrance_game.dat151.rel',
  'audio/prompt_block_game.dat151.rel',
  'audio/prompt_dining_game.dat151.rel',
  'audio/prompt_block3_game.dat151.rel',
  'audio/prompt_block1_game.dat151.rel',
  'audio/prompt_cells_game.dat151.rel',
  'audio/prompt_workshop_game.dat151.rel',
  'audio/prompt_newinmates_game.dat151.rel',
  'audio/prompt_admin_game.dat151.rel'
}

escrow_ignore {
  'stream/*.ytd',
  'stream/*.ymap',
  'stream/*.ytyp',
  'stream/unlocked/**',
  'stream/vanilla/**',
  'stream/newplacement/**'
}
dependency '/assetpacks'