-- Copyright (c) 2025 JMBH. All rights reserved.
--   ______ _      ______ _____ _______ _____   ____  _   _            _____
--  |  ____| |    |  ____/ ____|__   __|  __ \ / __ \| \ | |     /\   / ____|
--  | |__  | |    | |__ | |       | |  | |__) | |  | |  \| |    /  \ | |
--  |  __| | |    |  __|| |       | |  |  _  /| |  | | . ` |   / /\ \| |
--  | |____| |____| |___| |____   | |  | | \ \| |__| | |\  |  / ____ \ |____
--  |______|______|______\_____|  |_|  |_|  \_\\____/|_| \_| /_/    \_\_____|
--
--                      The most advanced fiveM anticheat.
--                        https://electron-services.com
--

fx_version 'cerulean'
game 'gta5'

author 'Electron Services'
description 'The most advanced fiveM anticheat.'
version '1.0.0'
lua54 'yes'

node_version '22'
use_experimental_fxv2_oal "yes"


files {
    "src/include/client.lua",
    "web/**/*",
}




ui_page "web/index.html"


client_scripts {
    "src/client/main.lua",
}

server_scripts {
    "src/server/main.lua",
    "src/server/main.js",
}
