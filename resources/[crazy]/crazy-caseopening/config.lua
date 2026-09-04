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
-- to 100 (normalized at roll time) - written as whole numbers here since
-- they do sum to 100 per tier, purely for readability. Tier totals:
-- common 60, uncommon 25, rare 10, epic 4, legendary 1.
--
-- Cash rewards show their actual dollar range as text client-side (the
-- exact rolled amount once it's actually won) - no icon or image needed.
-- Item rewards reuse existing ox_inventory items and their real icons
-- (nui://ox_inventory/web/images/<item>.png, ox_inventory's own default-
-- image convention - the item key IS the filename unless items.lua
-- overrides it with client.image).
--
-- Epic and legendary are cash-only, not an oversight: every epic/
-- legendary item in ox_inventory's own database is a heist tool, a
-- vehicle-mod part, or food - nothing that reads as a fun case pull, so
-- rather than hand out break-in gear or mislabel a common/rare item as
-- epic, those two tiers stay cash, same as most CS-style cases have a
-- purely-cash top end alongside the actual skins.
Config.Rewards = {
    -- Common (60%)
    { id = 'garbage',     type = 'item', item = 'garbage',     label = 'Garbage',            rarity = 'common', weight = 6, image = true },
    { id = 'steel',       type = 'item', item = 'steel',       label = 'Steel',              rarity = 'common', weight = 6, image = true },
    { id = 'rubber',      type = 'item', item = 'rubber',      label = 'Rubber',             rarity = 'common', weight = 6, image = true },
    { id = 'metalscrap',  type = 'item', item = 'metalscrap',  label = 'Metal Scrap',        rarity = 'common', weight = 6, image = true },
    { id = 'iron',        type = 'item', item = 'iron',        label = 'Iron',               rarity = 'common', weight = 6, image = true },
    { id = 'copper',      type = 'item', item = 'copper',      label = 'Copper',             rarity = 'common', weight = 6, image = true },
    { id = 'plastic',     type = 'item', item = 'plastic',     label = 'Plastic',            rarity = 'common', weight = 6, image = true },
    { id = 'firework1',   type = 'item', item = 'firework1',   label = '2Brothers Firework', rarity = 'common', weight = 6, image = true },
    { id = 'toaster',     type = 'item', item = 'toaster',     label = 'Toaster',            rarity = 'common', weight = 6, image = true },
    { id = 'binoculars',  type = 'item', item = 'binoculars',  label = 'Binoculars',         rarity = 'common', weight = 6, image = true },

    -- Uncommon (25%) - armour/parachute are non-stackable equipment, so
    -- they're pinned to count = 1 regardless of the uncommon default (10
    -- vests would just be wasted inventory slots).
    { id = 'armour',          type = 'item', item = 'armour',          label = 'Bulletproof Vest', rarity = 'uncommon', weight = 4, image = true, count = 1 },
    { id = 'parachute',       type = 'item', item = 'parachute',       label = 'Parachute',        rarity = 'uncommon', weight = 4, image = true, count = 1 },
    { id = 'screwdriverset',  type = 'item', item = 'screwdriverset',  label = 'Screwdriver Set',  rarity = 'uncommon', weight = 4, image = true },
    { id = 'electronickit',   type = 'item', item = 'electronickit',   label = 'Electronic Kit',   rarity = 'uncommon', weight = 4, image = true },
    { id = 'firstaid',        type = 'item', item = 'firstaid',        label = 'First Aid',        rarity = 'uncommon', weight = 3, image = true },
    { id = 'cash_rolls',      type = 'item', item = 'cash_rolls',      label = 'Cash Rolls',       rarity = 'uncommon', weight = 3, image = true },
    { id = 'diving_gear',     type = 'item', item = 'diving_gear',     label = 'Diving Gear',      rarity = 'uncommon', weight = 3, image = true },

    -- Rare (10%) - the DB only has 6 non-excluded rare items, so this
    -- tier is 6 items + 1 cash entry to round out to 7 slots.
    { id = 'cash_rare',          type = 'cash', amount = { 750, 1200 }, label = 'Big Money',          rarity = 'rare', weight = 3 },
    { id = 'diamond_ring',       type = 'item', item = 'diamond_ring',       label = 'Diamond',            rarity = 'rare', weight = 1.5, image = true },
    { id = 'rolex',              type = 'item', item = 'rolex',              label = 'Golden Watch',       rarity = 'rare', weight = 1.5, image = true },
    { id = 'goldchain',          type = 'item', item = 'goldchain',          label = 'Golden Chain',       rarity = 'rare', weight = 1.5, image = true },
    { id = 'antipatharia_coral', type = 'item', item = 'antipatharia_coral', label = 'Antipatharia Coral', rarity = 'rare', weight = 1,   image = true },
    { id = 'dendrogyra_coral',   type = 'item', item = 'dendrogyra_coral',   label = 'Dendrogyra Coral',   rarity = 'rare', weight = 1,   image = true },
    { id = 'cash_band',          type = 'item', item = 'cash_band',          label = 'Cash Band',          rarity = 'rare', weight = 0.5, image = true },

    -- Epic (4%) - cash only, see note above.
    { id = 'epic_cash1', type = 'cash', amount = { 1500, 2000 }, label = 'Thick Envelope',    rarity = 'epic', weight = 0.8 },
    { id = 'epic_cash2', type = 'cash', amount = { 2000, 2500 }, label = 'Briefcase of Cash', rarity = 'epic', weight = 0.8 },
    { id = 'epic_cash3', type = 'cash', amount = { 2500, 3000 }, label = 'Cash Vault',        rarity = 'epic', weight = 0.8 },
    { id = 'epic_cash4', type = 'cash', amount = { 3000, 3500 }, label = 'Armored Deposit',   rarity = 'epic', weight = 0.8 },
    { id = 'epic_cash5', type = 'cash', amount = { 3500, 4000 }, label = 'Executive Payout',  rarity = 'epic', weight = 0.8 },

    -- Legendary (1%) - cash only, see note above.
    { id = 'legendary_cash1', type = 'cash', amount = { 5000, 6500 },  label = 'Lucky Break',  rarity = 'legendary', weight = 0.5 },
    { id = 'legendary_cash2', type = 'cash', amount = { 6500, 8500 },  label = 'Grand Prize',  rarity = 'legendary', weight = 0.3 },
    { id = 'jackpot',         type = 'cash', amount = { 8500, 10000 }, label = 'JACKPOT',      rarity = 'legendary', weight = 0.2 },
}
