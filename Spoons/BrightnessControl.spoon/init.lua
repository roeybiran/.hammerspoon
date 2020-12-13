--- === BrightnessControl ===
---
--- Enters a transient mode in which the left and right arrow keys decrease and increase the system's brightness, respectively.

local Hotkey = require("hs.hotkey")
local Eventtap = require("hs.eventtap")

local obj = {}

obj.__index = obj
obj.name = "BrightnessControl"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local brightnessControlModal = nil

local function systemKey(key)
  Eventtap.event.newSystemKeyEvent(string.upper(key), true):post()
  Eventtap.event.newSystemKeyEvent(string.upper(key), false):post()
end

local function increaseBrightness()
  systemKey("BRIGHTNESS_UP")
end

local function decreaseBrightness()
  systemKey("BRIGHTNESS_DOWN")
end

--- BrightnessControl:start()
---
--- Method
---
--- Starts the module.
---
function obj.start()
  brightnessControlModal:enter()
end

--- BrightnessControl:stop()
---
--- Method
---
--- Stops the module. Bound to the escape and return keys.
---
function obj.stop()
  brightnessControlModal:exit()
end

--- BrightnessControl.increaseBrightnessKey
---
--- Variable
---
--- A hotkey that increases brightness. It's a table that must include 2 keys, "mods" and "key", each must be of the same type as the first 2 parameters to the `hs.hotkey.bind` method. Defaults to →.
obj.increaseBrightnessKey = {mods = {}, key = "right"}

--- BrightnessControl.decreaseBrightnessKey
---
--- Variable
---
--- A hotkey that decreases brightness. It's a table that must include 2 keys, "mods" and "key", each must be of the same type as the first 2 parameters to the `hs.hotkey.bind` method. Defaults to ←.
obj.decreaseBrightnessKey = {mods = {}, key = "left"}

function obj.init()
  brightnessControlModal = Hotkey.modal.new()
  brightnessControlModal:bind(
    obj.increaseBrightnessKey.mods,
    obj.increaseBrightnessKey.key,
    nil,
    increaseBrightness,
    increaseBrightness,
    nil
  )
  brightnessControlModal:bind(
    obj.decreaseBrightnessKey.mods,
    obj.decreaseBrightnessKey.key,
    nil,
    decreaseBrightness,
    decreaseBrightness,
    nil
  )
  brightnessControlModal:bind({}, "escape", nil, obj.stop, nil, nil)
  brightnessControlModal:bind({}, "return", nil, obj.stop, nil, nil)
end

return obj
