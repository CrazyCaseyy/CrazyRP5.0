# Contributing Compatibility Patches

## Overview

The `tstudio_zmapdata` system automatically loads and applies compatibility patches when conflicting maps are detected. When maps conflict, create a **FiveM patch resource** that gets started last and overrides the conflicting vanilla files.

## Quick Example

Your map conflicts with TStudio Legion Square? Here's what to do:

**1. Create patch resource** (`yourname_zpatch_casino_legion/`):
```lua
-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
```
```
stream/
└── fixed_props.ymap  (your fix files)
```

**2. Submit to GitHub**: https://github.com/TStudio3d/tstudio_maps_patches

**3. Add config** (`tstudio_zmapdata/patches/yourname.lua`):
```lua
return {
    creatorName = "Your Name",
    patches = {
        {
            name = "Fix for Awesome Casino & Legion Square",
            requiredMaps = {"yourname_casino", "tstudio_legionsquare"},
            fixResource = "yourname_zpatch_casino_legion"
        }
    }
}
```

**4. Update manifest** (`patches/_manifest.lua`):
```lua
return {
    "tstudio",
    "yourname",  -- Add your name
}
```

**Result**: System auto-detects both maps and starts your patch!

## Why Contribute?

- ✅ Reduce support tickets (you likely already provide these patches to customers)
- ✅ Automatic detection and loading
- ✅ Professional, centralized solution
- ✅ No manual configuration for server owners

## Best Practices

- **Naming**: `creatorname_zpatch_map1_map2`
- **Files**: Only include minimal files that fix the actual conflict
- **Testing**: Test thoroughly with both maps before submitting

## How to Submit

**Option 1 - GitHub PR** (Recommended):
1. Fork https://github.com/TStudio3d/tstudio_maps_patches
2. Add your patch resource
3. Submit PR

**Option 2 - GitHub Issue**:
Create issue with download link and patch details

**Option 3 - Discord**:
Share files at https://discord.gg/tstudio

---

**Note**: Most creators already provide patches - this just makes them automatic!

