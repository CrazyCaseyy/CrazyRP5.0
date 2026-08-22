# crazy-multichar

A custom external multicharacter select screen for **QBX Core**
(`qbx_core`), styled to match `ox_lib`'s own look (near-black translucent
panels, `#1573ed` accent blue, Geom Graphic display font) — built from
scratch, not using ox_lib's actual menu components. It talks to the exact
same server callbacks/events qbx_core's own built-in screen uses, so it's
a drop-in visual replacement, not a different character system.

- Focuses on one character slot at a time, rather than showing all slots
  side by side. Slot 1 is focused automatically on load; number buttons
  (`1`/`2`/`3`, bottom of screen) switch which slot is previewed.
- The previewed ped shows the character's REAL saved look (clothes, face,
  hair, tattoos — everything illenium-appearance stores), fetched via
  `crazy-multichar:server:getAppearance` and applied with
  illenium-appearance's own `setPlayerAppearance` export — not just a
  bare gender model. Empty slots fall back to a plain default model.
- Camera is fixed (no orbit) so you can actually look at the character
  you're previewing — see `Config.PreviewOrbit.enabled` if you want the
  slow spin back.
- A character "dossier" panel appears for the focused slot's character:
  name, gender, birthdate, nationality, account number, bank, cash,
  job + grade, gang + grade, phone number. Empty slots show a simple
  "no character here yet" panel with a CREATE CHARACTER action instead.
- Three slots, sourced from qbx_core's own
  `config.characters.defaultNumberOfCharacters` (already `3` on this
  server) — not hardcoded here, same single source of truth qbx_core's
  built-in screen uses.
- Brand-new characters pick a starting apartment as step 2 of creation
  (`Config.Apartments` — currently just Alta Apartments).

## Requirements

- [`qbx_core`](https://github.com/Qbox-project/qbx_core)
- [`ox_lib`](https://github.com/overextended/ox_lib)
- `oxmysql` — the appearance preview reads illenium-appearance's
  `playerskins` table directly (see `server/server.lua`).
- `illenium-appearance` — its `setPlayerAppearance` client export renders
  the real saved look onto the preview ped.
- `qbx_spawn` (optional but installed on this server) — existing
  characters are handed off to it for spawn-location choice, exactly
  like qbx_core's own built-in screen does.

## Install

1. `qbx_core/config/client.lua` → `useExternalCharacters = true` (already
   set).
2. `server.cfg`, started after its dependencies (already wired):
   ```
   ensure ox_lib
   ensure qbx_core
   ensure crazy-multichar
   ```

## How it talks to qbx_core

Same contract qbx_core's own built-in screen uses (see
`qbx_core/client/character.lua` and `server/character.lua`):

| Action | Call |
|---|---|
| Fetch characters + slot count | `lib.callback.await('qbx_core:server:getCharacters', false)` |
| Fetch a citizen's saved appearance for preview | `lib.callback.await('crazy-multichar:server:getAppearance', false, citizenid)` (this resource's own `server/server.lua`, reads illenium-appearance's `playerskins` table directly — not a qbx_core call) |
| Create a character | `lib.callback.await('qbx_core:server:createCharacter', false, { firstname, lastname, nationality, gender, birthdate })` |
| Load an existing character | `lib.callback.await('qbx_core:server:loadCharacter', false, citizenid)` |
| Delete a character | `TriggerServerEvent('qbx_core:server:deleteCharacter', citizenid)` (documented backward-compatible net event) |

After a character is loaded/created, this resource fires
`TriggerServerEvent('QBCore:Server:OnPlayerLoaded')` and
`TriggerEvent('QBCore:Client:OnPlayerLoaded')` itself — qbx_core's own
built-in screen does this too (`client/character.lua` → `spawnAt()`), and
skipping it would leave jobs/gangs/HUD/etc. never told the player
actually loaded.

**Existing characters**, when `qbx_spawn` is running, are handed off to it
entirely (`qb-spawn:client:setupSpawns` / `qb-spawn:client:openUI`) — the
same thing qbx_core's own screen does — so they get the normal
Legion Square / Paleto Bay / Motels / last-location picker. If
`qbx_spawn` isn't running, they spawn straight at their saved
`position` instead.

**New characters** go through a starting-apartment picker as step 2 of
creation (`Config.Apartments` — currently just Alta Apartments). This is
a location choice only, not a housing/property system — it doesn't grant
ownership, rent, or an interior shell, and nothing here persists it
beyond the initial spawn. `qbx_apartments` isn't installed on this
server, so this is a lightweight stand-in for it rather than a hand-off;
if `Config.Apartments` is ever emptied out, new characters fall back to
`Config.NewCharacterSpawn` (kept in sync with qbx_core's own
`config.shared.defaultSpawn`).

## Customizing

- **Colors/theme** — `html/style.css`, the `:root` custom properties
  (`--ox-blue`, `--ox-panel`, etc).
- **Camera / staging position** — `config.lua`, `Config.SpawnPoint` /
  `Config.CameraPoint`.
- **Slot count** — qbx_core's own
  `config.characters.defaultNumberOfCharacters` /
  `playersNumberOfCharacters`, not here.
- **Info panel fields** — `html/script.js`, `renderInfoPanel()`.
- **Preview camera** — `config.lua`, `Config.PreviewOrbit.enabled` (off
  by default — set `true` for the old slow-spin showcase camera).
- **Apartments** — `config.lua`, `Config.Apartments`. Add more entries to
  turn the single-option "MOVE IN" step into a real picker; the UI
  already handles any number of them.

## Debugging

`Config.Debug = true` (on by default) prints `[crazy-multichar]`
checkpoints to F8. `/crazy_multichar_open` opens the screen manually
in-game, bypassing spawn detection, to test the NUI in isolation.
