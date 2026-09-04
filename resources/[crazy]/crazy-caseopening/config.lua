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

-- How many of an item-type reward you actually get - scaled so the
-- common stuff feels like a real haul and the rare stuff stays rare.
-- Only used for type='item' entries (cash rewards use their own
-- `amount` range instead). An entry can override this with its own
-- `count` field - used below for non-stackable equipment (armour,
-- parachute), where handing out a stack of 10 vests makes no sense.
Config.RarityItemAmount = {
    common = 25,
    uncommon = 10,
    rare = 3,
    epic = 2,
    legendary = 1,
}

-- What's actually in the case. `weight` is relative, not required to sum
-- to any particular number (normalized against the tier's own total at
-- roll time). Tier totals: common 42, uncommon 26, rare 8, epic 4,
-- legendary 1 - every tier except legendary has exactly one cash entry
-- alongside its items; legendary stays cash-only.
--
-- Cash rewards show ox_inventory's own money.png with the actual dollar
-- amount as the label (the exact rolled figure once it's actually won).
-- Item rewards reuse existing ox_inventory items and their real icons -
-- `image = true` uses ox_inventory's own default-image convention
-- (nui://ox_inventory/web/images/<item key>.png), or set `image` to an
-- exact filename string when items.lua's own client.image override
-- doesn't match the item key (see cash_band below).
Config.Rewards = {
    -- Common (42) - garbage/binoculars/firework1/toaster removed.
    { id = 'cash_common', type = 'cash', amount = { 250, 750 }, label = 'Petty Cash', rarity = 'common', weight = 6 }, -- 5x
    { id = 'steel',       type = 'item', item = 'steel',       label = 'Steel',              rarity = 'common', weight = 6, image = true },
    { id = 'rubber',      type = 'item', item = 'rubber',      label = 'Rubber',             rarity = 'common', weight = 6, image = true },
    { id = 'metalscrap',  type = 'item', item = 'metalscrap',  label = 'Metal Scrap',        rarity = 'common', weight = 6, image = true },
    { id = 'iron',        type = 'item', item = 'iron',        label = 'Iron',               rarity = 'common', weight = 6, image = true },
    { id = 'copper',      type = 'item', item = 'copper',      label = 'Copper',             rarity = 'common', weight = 6, image = true },
    { id = 'plastic',     type = 'item', item = 'plastic',     label = 'Plastic',            rarity = 'common', weight = 6, image = true },

    -- Uncommon (26) - first aid removed. armour/parachute are pinned to
    -- count = 1 since they're non-stackable equipment (10 vests would
    -- just be wasted slots); electronickit/screwdriverset are pinned to
    -- count = 1 too, by choice, capping how many of those specifically
    -- get handed out despite the uncommon default being 10.
    { id = 'cash_uncommon',   type = 'cash', amount = { 1000, 2500 }, label = 'Fat Stack', rarity = 'uncommon', weight = 4 }, -- 5x
    { id = 'armour',          type = 'item', item = 'armour',          label = 'Bulletproof Vest', rarity = 'uncommon', weight = 4, image = true, count = 1 },
    { id = 'parachute',       type = 'item', item = 'parachute',       label = 'Parachute',        rarity = 'uncommon', weight = 4, image = true, count = 1 },
    { id = 'screwdriverset',  type = 'item', item = 'screwdriverset',  label = 'Screwdriver Set',  rarity = 'uncommon', weight = 4, image = true, count = 1 },
    { id = 'electronickit',   type = 'item', item = 'electronickit',   label = 'Electronic Kit',   rarity = 'uncommon', weight = 4, image = true, count = 1 },
    { id = 'cash_rolls',      type = 'item', item = 'cash_rolls',      label = 'Cash Rolls',       rarity = 'uncommon', weight = 3, image = true },
    { id = 'diving_gear',     type = 'item', item = 'diving_gear',     label = 'Diving Gear',      rarity = 'uncommon', weight = 3, image = true },

    -- Rare (8) - antipatharia_coral/dendrogyra_coral removed. Already
    -- had exactly one cash entry (cash_rare), so nothing to add here.
    { id = 'cash_rare',    type = 'cash', amount = { 3750, 6000 }, label = 'Big Money',    rarity = 'rare', weight = 3 }, -- 5x
    { id = 'diamond_ring', type = 'item', item = 'diamond_ring', label = 'Diamond',       rarity = 'rare', weight = 1.5, image = true },
    { id = 'rolex',        type = 'item', item = 'rolex',        label = 'Golden Watch',  rarity = 'rare', weight = 1.5, image = true },
    { id = 'goldchain',    type = 'item', item = 'goldchain',    label = 'Golden Chain',  rarity = 'rare', weight = 1.5, image = true },
    -- ox_inventory's own item DB overrides this one's image to
    -- "cashband.png" (no underscore) instead of the usual item-key
    -- convention, so it needs the actual filename spelled out here too.
    { id = 'cash_band',    type = 'item', item = 'cash_band',    label = 'Cash Band',     rarity = 'rare', weight = 0.5, image = 'cashband.png' },

    -- Epic (2) - the lockpick plus one cash entry, evenly weighted.
    { id = 'advancedlockpick', type = 'item', item = 'advancedlockpick', label = 'Advanced Lockpick', rarity = 'epic', weight = 4, image = true },
    { id = 'cash_epic',        type = 'cash', amount = { 7500, 10000 },  label = 'High Roller',      rarity = 'epic', weight = 4 },

    -- Legendary (1) - cash only, 2.5x.
    { id = 'legendary_cash1', type = 'cash', amount = { 12500, 16250 }, label = 'Lucky Break',  rarity = 'legendary', weight = 0.5 },
    { id = 'legendary_cash2', type = 'cash', amount = { 16250, 21250 }, label = 'Grand Prize',  rarity = 'legendary', weight = 0.3 },
    { id = 'jackpot',         type = 'cash', amount = { 21250, 25000 }, label = 'JACKPOT',      rarity = 'legendary', weight = 0.2 },
}
