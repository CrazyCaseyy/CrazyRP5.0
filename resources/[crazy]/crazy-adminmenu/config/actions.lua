-- Every individually-permissioned action in the admin menu: id (wire name,
-- never shown/changed), category + label (for the owner-facing Action
-- Permissions editor in the Admins tab), and default (the tier it starts
-- at until an owner overrides it - server/permissions.lua persists
-- overrides in crazy_adminmenu_action_perms and merges them over these
-- defaults at runtime, so editing this list only ever changes what a
-- FRESH install starts with, never something already overridden).
--
-- This replaces config/server.lua's old static commandPerms/eventPerms
-- tables (one tier per whole feature, e.g. every player "General" action
-- sharing a single playerOptionsGeneral tier) with one entry per actual
-- button/command, and moves the source of truth from this file into the
-- database so owners can change any of it in-game without editing Lua or
-- restarting anything - see server/permissions.lua's hasActionPerm.
return {
    { id = 'menu_open', category = 'General', label = 'Open Admin Menu (/admin)', default = 'mod' },

    -- Players tab
    { id = 'player_kill', category = 'Players', label = 'Kill Player', default = 'mod' },
    { id = 'player_revive', category = 'Players', label = 'Revive Player', default = 'mod' },
    { id = 'player_freeze', category = 'Players', label = 'Freeze / Unfreeze Player', default = 'mod' },
    { id = 'player_goto', category = 'Players', label = 'Go To Player', default = 'mod' },
    { id = 'player_bring', category = 'Players', label = 'Bring Player', default = 'mod' },
    { id = 'player_sit', category = 'Players', label = 'Sit On Player', default = 'mod' },
    { id = 'player_kick', category = 'Players', label = 'Kick Player', default = 'mod' },
    { id = 'player_ban', category = 'Players', label = 'Ban Player', default = 'admin' },
    { id = 'player_editData', category = 'Players', label = 'Edit Character Data', default = 'admin' },
    { id = 'player_clothing', category = 'Players', label = 'Open Clothing Menu', default = 'admin' },
    { id = 'player_inventory', category = 'Players', label = 'View / Edit Inventory', default = 'admin' },

    -- Self Tools
    { id = 'self_noclip', category = 'Self Tools', label = 'Noclip', default = 'mod' },
    { id = 'self_revive', category = 'Self Tools', label = 'Self Revive', default = 'mod' },
    { id = 'self_invisible', category = 'Self Tools', label = 'Invisible', default = 'mod' },
    { id = 'self_godmode', category = 'Self Tools', label = 'Godmode', default = 'mod' },
    { id = 'self_names', category = 'Self Tools', label = 'Player Names', default = 'mod' },
    { id = 'self_blips', category = 'Self Tools', label = 'Player Blips', default = 'mod' },
    { id = 'self_vehicleGodmode', category = 'Self Tools', label = 'Vehicle Godmode', default = 'mod' },
    { id = 'self_infiniteAmmo', category = 'Self Tools', label = 'Infinite Ammo', default = 'mod' },
    { id = 'self_cuff', category = 'Self Tools', label = 'Cuff Self', default = 'mod' },
    { id = 'self_setModel', category = 'Self Tools', label = 'Set Ped Model (/setmodel)', default = 'admin' },

    -- Vehicles tab
    { id = 'vehicle_spawn', category = 'Vehicles', label = 'Spawn Vehicle', default = 'admin' },
    { id = 'vehicle_fix', category = 'Vehicles', label = 'Fix Vehicle', default = 'mod' },
    { id = 'vehicle_delete', category = 'Vehicles', label = 'Delete Vehicle', default = 'mod' },
    { id = 'vehicle_takeOwnership', category = 'Vehicles', label = 'Take Ownership (/admincar)', default = 'admin' },
    { id = 'vehicle_setPlate', category = 'Vehicles', label = 'Set Plate', default = 'mod' },

    -- Server tab
    { id = 'server_weather', category = 'Server', label = 'Set Weather', default = 'mod' },
    { id = 'server_time', category = 'Server', label = 'Set Time', default = 'mod' },
    { id = 'server_radio', category = 'Server', label = 'Radio Lookup', default = 'mod' },
    { id = 'server_stash', category = 'Server', label = 'Pull Stash', default = 'admin' },

    -- Dev Tools tab
    { id = 'dev_coords', category = 'Dev Tools', label = 'Coords Overlay', default = 'admin' },
    { id = 'dev_vehicleInfo', category = 'Dev Tools', label = 'Vehicle Info Overlay', default = 'admin' },
    { id = 'dev_laser', category = 'Dev Tools', label = 'Laser Pointer', default = 'admin' },
    { id = 'dev_copyCoords', category = 'Dev Tools', label = 'Copy Coords / Heading (/vec2, /vec3, /vec4, /heading)', default = 'admin' },

    -- Reports tab
    { id = 'reports_view', category = 'Reports', label = 'View / Reply to Reports', default = 'mod' },

    -- Ban Logs tab
    { id = 'bans_view', category = 'Ban Logs', label = 'View Ban Logs', default = 'admin' },
    { id = 'bans_unban', category = 'Ban Logs', label = 'Unban Player', default = 'admin' },

    -- Characters tab
    { id = 'characters_search', category = 'Characters', label = 'Search Characters (online or not)', default = 'admin' },

    -- Admins tab - lets whoever holds it grant/edit OTHER players' staff
    -- tier (Support/Mod/Admin) from the Admins tab's Staff list, without
    -- needing to be an owner themselves. Deliberately defaulted to 'owner'
    -- (not 'admin', unlike everything else in this file) so it's off for
    -- every staff rank out of the box - an owner has to explicitly hand it
    -- out here, per-tier or per-player, same as any other action. Owner
    -- itself still can never be granted this way (server/permissions.lua's
    -- setStaffTier only ever accepts support/mod/admin), so this can't be
    -- used to create more owners.
    { id = 'admin_grantStaff', category = 'Admins', label = 'Grant/Edit Staff Tiers (Support/Mod/Admin)', default = 'owner' },
}
