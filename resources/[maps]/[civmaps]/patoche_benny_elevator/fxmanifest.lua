shared_script "@ReaperV4/imports/bypass.lua"
shared_script "@ReaperV4/imports/bypass_s.lua"
shared_script "@ReaperV4/imports/bypass_c.lua"
lua54 "yes" -- needed for Reaper


fx_version 'cerulean'
lua54 'yes'
game 'gta5'

client_scripts{
	"lang.lua",
	"client.lua"
}

server_scripts{ 
	"server.lua"
}

escrow_ignore {
    'lang.lua'
}
dependency '/assetpacks'
