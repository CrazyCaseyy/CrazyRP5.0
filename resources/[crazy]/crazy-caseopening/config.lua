Config = {}

-- The item this whole resource is built around - already registered in
-- ox_inventory/data/items.lua as crazy-dailytasks' reward item.
Config.ItemName = 'case'

-- 5-tier rarity, matching ox_inventory's own item rarity convention
-- (used elsewhere in the inventory UI) so this feels consistent rather
-- than inventing a separate system.
Config.RarityColors = {
    common = '#b0b3b8',
    uncommon = '#3ddc84',
    rare = '#1573ed',
    epic = '#a855f7',
    legendary = '#f5a623',
}

-- What's actually in the case. `weight` is relative, not required to sum
-- to 100 (normalized at roll time) - written as whole numbers here since
-- they do sum to 100, purely for readability.
--
-- Cash rewards use icon = 'dollar' or 'trophy' (drawn client-side, no
-- image asset needed). Item rewards reuse existing ox_inventory items
-- and their real icons (nui://ox_inventory/web/images/<item>.png).
Config.Rewards = {
    { id = 'cash_small',   type = 'cash', amount = { 50, 100 },     label = 'Petty Cash',   rarity = 'common',    weight = 30, icon = 'dollar' },
    { id = 'cash_small2',  type = 'cash', amount = { 100, 150 },    label = 'Loose Change', rarity = 'common',    weight = 30, icon = 'dollar' },
    { id = 'cash_med',     type = 'cash', amount = { 200, 350 },    label = 'Decent Stack', rarity = 'uncommon',  weight = 15, icon = 'dollar' },
    { id = 'cash_med2',    type = 'cash', amount = { 350, 500 },    label = 'Fat Stack',    rarity = 'uncommon',  weight = 10, icon = 'dollar' },
    { id = 'cash_big',     type = 'cash', amount = { 750, 1200 },   label = 'Big Money',    rarity = 'rare',      weight = 4,  icon = 'dollar' },
    { id = 'diamond_ring', type = 'item', item = 'diamond_ring',    label = 'Diamond',      rarity = 'rare',      weight = 2,  image = true },
    { id = 'rolex',        type = 'item', item = 'rolex',           label = 'Golden Watch', rarity = 'rare',      weight = 2,  image = true },
    { id = 'goldchain',    type = 'item', item = 'goldchain',       label = 'Golden Chain', rarity = 'rare',      weight = 2,  image = true },
    { id = 'goldbar',      type = 'item', item = 'goldbar',         label = 'Gold Bar',     rarity = 'epic',      weight = 4,  image = true },
    { id = 'jackpot',      type = 'cash', amount = { 5000, 10000 }, label = 'JACKPOT',      rarity = 'legendary', weight = 1,  icon = 'trophy' },
}
