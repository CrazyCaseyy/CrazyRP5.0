Config = {}

-- The rental clerk NPC, doing a clipboard scenario in place.
Config.Ped = {
    model = 'a_m_m_business_01',
    coords = vec4(-239.43, -991.27, 28.29, 71.09),
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

-- Where a rented vehicle is spawned in and the player is warped into it.
Config.SpawnPoint = vec4(-236.06, -991.08, 28.21, 159.19)

-- Rental options shown in the ox_lib menu. `model` must be a valid spawn
-- code (see [qbx]/qbx_core/shared/vehicles.lua).
Config.Vehicles = {
    { model = 'panto', label = 'Panto', price = 500 },
    { model = 'futo', label = 'Futo', price = 500 },
    { model = 'faggio', label = 'Faggio', price = 500 },
}
