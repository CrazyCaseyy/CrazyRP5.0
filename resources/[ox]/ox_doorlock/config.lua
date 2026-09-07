---@type DoorlockConfig
---@diagnostic disable-next-line: missing-fields
Config = {}

---Trigger a notification on the client when the door state is successfully updated.
Config.Notify = false

---Create a persistent notification while in-range of a door, prompting to lock/unlock.
-- The "[E] Lock/Unlock door" ox_lib text UI prompt (locales/en.json already
-- has the "[E]" baked into the label) - same lib.showTextUI style used
-- everywhere else in this project instead of a floating world sprite.
Config.DrawTextUI = true

---Set the properties used by [DrawSprite](https://docs.fivem.net/natives/?_0xE7FFAE5EBF23D890).
-- Disabled - the lock icon hovering over every door is replaced by the
-- DrawTextUI prompt above.
Config.DrawSprite = false

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
