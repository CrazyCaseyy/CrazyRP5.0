

fx_version 'cerulean'
game 'gta5'
lua54 "yes"
version '1.4.0'

dependencies {
    '/server:4752',
}

server_scripts {
	"config.lua",
	"loader.lua",
	'server/framework.lua', 
	'server/utils.lua', 
	'server/stats.lua',
	'server/leaderboards.lua',
	'server/main.lua',
	'server/peerjsfallback.lua'
}

client_scripts {
	'client/ui/TimerBar.lua', 
	'client/ui/helpbuttons.lua', 
	"config.lua",
	"loader.lua",
	'locales/**/*.lua',
	'client/framework.lua', 
	'client/utils.lua', 
	'client/ui/menu.lua', 
	'client/sceneped.lua', 
	'client/peerjs.lua',
	'client/stats.lua',
	'client/leaderboards.lua',
	'client/main.lua',
	'client/hockey.lua',
	
}

escrow_ignore {
	"config.lua",
	"loader.lua",
	'client/hockey.lua',
	'server/framework.lua', 
	'client/framework.lua',
	'client/utils.lua',
	'locales/**/*.lua',
}

files {
	'client/nui/**/*'
}

ui_page 'client/nui/index.html'
data_file 'DLC_ITYP_REQUEST' 'stream/props/rcore_airhockey.ytyp'

dependency '/assetpacks'

