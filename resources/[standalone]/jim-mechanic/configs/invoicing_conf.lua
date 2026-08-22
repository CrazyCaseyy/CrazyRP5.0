Config = Config or {}

-- Quick-select services for the crazy-invoicing card reader (see
-- configs/_system_conf.lua -> System.Billing = "crazy"). Picking one bills
-- the nearest customer for that amount instead of typing a description by
-- hand. "Custom Amount" is always added after this list for anything not
-- covered here (e.g. a one-off full repair priced by the automated system).
--
-- `name` matches the real ox_inventory item being installed, for reference -
-- these are labor/service charges, not the item's own value. Tune freely to
-- your economy (ManualRepairCost in repairbench_conf.lua runs 15-20k, so
-- these are scaled to sit under that).
Config.InvoiceMenu = {
    { name = 'turbo', label = 'Turbo Install', price = 3500 },
    { name = 'nos', label = 'NOS Install', price = 2500 },
    { name = 'bprooftires', label = 'Bulletproof Tires', price = 6000 },
    { name = 'antilag', label = 'Anti-Lag Install', price = 2000 },
    { name = 'harness', label = 'Race Harness Install', price = 900 },
    { name = 'tint_supplies', label = 'Window Tint', price = 800 },
    { name = 'paintcan', label = 'Paint Job', price = 1500 },
    { name = 'sparetire', label = 'Tire Change', price = 200 },
    { name = 'carbattery', label = 'Battery Replacement', price = 400 },
    { name = 'sparkplugs', label = 'Spark Plug Replacement', price = 250 },
    { name = 'axleparts', label = 'Axle Repair', price = 1200 },
    { name = 'newoil', label = 'Oil Change', price = 300 },
    { name = 'cleaningkit', label = 'Full Detail', price = 250 },
}
