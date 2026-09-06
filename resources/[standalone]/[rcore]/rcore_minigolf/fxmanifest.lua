

fx_version "cerulean"
lua54 "yes"
game "gta5"

version "1.0.3"

dependencies {
    'rcore_minigolf_assets'
}

client_scripts {
    -- Company
    "client/init.lua",
    "CompanyModule/client/init.lua",
    "CompanyModule/client/cache.lua",
    "CompanyModule/client/utils.lua",

    "CompanyModule/client/player_events.lua",

    "CompanyModule/client/company/drawable/drawable_entities.lua",
    "CompanyModule/client/company/drawable/zone_events.lua",
    "CompanyModule/client/company/drawable/drawable_delete.lua",

    "CompanyModule/client/company/buy_company.lua",
    "CompanyModule/client/company/boss_menu.lua",

    "CompanyModule/client/company/blips/blip.lua",
    "CompanyModule/client/fetch_identifier.lua",
    "CompanyModule/client/fetch_my_companies.lua",

    "CompanyModule/client/editable_events.lua",

    "CompanyModule/client/menu/*.lua",
    "CompanyModule/client/menu/boss/*.lua",
    "CompanyModule/client/menu/boss/employees/*.lua",
    "CompanyModule/client/menu/boss/employees/grades/*.lua",
    "CompanyModule/client/menu/boss/employees/fire_hire/*.lua",

    "client/objectCreator.lua",
    "client/golfblockmap.lua",
    "client/const.lua",
    "client/utils.lua",
    "client/geometry.lua",
    "client/walk.lua",
    "client/minigolf.lua",
    "client/pieceextensions.lua",
    "client/ballaimer.lua",
    "client/pedanimcontroller.lua",
    "client/camcontroller.lua",
    "client/menus/*.lua",
    "client/editor.lua",
    "client/helpbuttons.lua",
    "client/client.lua",
    "client/gameplay.lua",
    "client/collectmission.lua",
    "client/timerbar.lua",
    "client/vehicle_keys.lua",
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    -- Company
    "server/framework/init.lua",
    "server/utils.lua",
    
    "server/framework/base/*.lua",

    "CompanyModule/server/request_cache.lua",
    "CompanyModule/server/fetch_identifier.lua",
    "CompanyModule/server/fetch_players.lua",
    "CompanyModule/server/fetch_company_online_players.lua",
    "CompanyModule/server/fetch_company_order_status.lua",
    "CompanyModule/server/payment_method.lua",

    "CompanyModule/server/company/*.lua",
    "CompanyModule/server/company/utils/*.lua",


    "config_server.lua",
    "server/framework/*.lua",
    "server/framework/inventory/*.lua",
    "server/main.lua",
}

shared_scripts {
    "const.lua",
    "config.lua",
    "langClass.lua",
    "locales/*.lua",
    "defaultLocales.lua",
    
    
    --Company
    "CompanyModule/const.lua",
    "CompanyModule/config/*.lua",
    "CompanyModule/shared/**/*.lua",

    "shared/**/*",
}

escrow_ignore {
    "config_server.lua",
    "config.lua",
    "const.lua",
    "server/framework/base/*.lua",
    "CompanyModule/config/*.lua",
    "server/framework/inventory/*.lua", "client/vehicle_keys.lua",
    "client/vehicle_keys.lua",
    "locales/*.lua",
}

files {
    "client/nui/**/*",
    "server/minigolf.json"
}

ui_page "client/nui/index.html"
dependency '/assetpacks'

