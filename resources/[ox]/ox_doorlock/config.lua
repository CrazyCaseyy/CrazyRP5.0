---@type DoorlockConfig
---@diagnostic disable-next-line: missing-fields
Config = {}

---Trigger a notification on the client when the door state is successfully updated.
Config.Notify = false

---Create a persistent notification while in-range of a door, prompting to lock/unlock.
-- Off - Config.DrawBadge below draws its own attached-to-the-door prompt
-- instead of this fixed-position ox_lib text UI one.
Config.DrawTextUI = false

---Set the properties used by [DrawSprite](https://docs.fivem.net/natives/?_0xE7FFAE5EBF23D890).
-- Off - replaced entirely by the custom "E" badge below, not GTA's native
-- lock-icon sprite texture.
Config.DrawSprite = false

---Draw a small blue "E" badge above the door itself (client/main.lua's
---drawDoorBadge) instead of a lock icon or the fixed ox_lib text UI prompt.
Config.DrawBadge = true

---Allow the specified ace principal to use 'command.doorlock'.
Config.CommandPrincipal = 'group.admin'

---Allow players with the 'command.doorlock' principal to use any door.
Config.PlayerAceAuthorised = false

---The default skill check difficulty when lockpicking a door.
Config.LockDifficulty = { 'easy', 'easy', 'medium' }

---Allow lockpicks to be used to lock an unlocked door.
Config.CanPickUnlockedDoors = false

---An array of items that function as lockpicks.
Config.LockpickItems = {
    'lockpick'
}

---Play sounds using game audio (sound natives) instead of through NUI.
Config.NativeAudio = true
