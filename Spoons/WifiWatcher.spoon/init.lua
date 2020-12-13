--- === WifiWatcher ===
---
--- Respond to changes in the current Wi-Fi network.
local audiodevice = require("hs.audiodevice")
local wifi = require("hs.wifi")
local timer = require("hs.timer")
local fnutils = require("hs.fnutils")
local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "WifiWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local settingKey = "RBMuteSoundWhenJoiningUnknownNetworks"
local isActive = false
local wifiWatcher = nil

--- WifiWatcher:userCallback()
---
--- Method
---
--- A callback to run when the Wi-Fi changes.
---
--- Returns:
---
---   * the module object, for method chaining.
---
function obj:userCallback()
  local knownNetworks = {
    "Biran",
    "Biran2",
    "BiranTLV",
    "rbrt",
    "Shely_or",
    "Harelzabari"
  }
  local muteSoundUnknownWifi = Settings.get(settingKey)
  local audioDevice = audiodevice.defaultOutputDevice()
  local currentWifi = wifi.currentNetwork()
  if fnutils.contains(knownNetworks, currentWifi) or muteSoundUnknownWifi == false then
    audioDevice:setOutputMuted(false)
  else
    audioDevice:setOutputMuted(true)
  end
  return self
end

local function wifiWatcherCallback()
  timer.doAfter(2, obj.userCallback)
end

--- WifiWatcher:start()
---
--- Method
---
--- Starts the Wi-Fi watcher.
---
--- Returns:
---
---   * the module object, for method chaining.
---
function obj:start()
  wifiWatcherCallback()
  wifiWatcher:start()
  isActive = true
  return self
end

--- WifiWatcher:stop()
---
--- Method
---
--- Stops the Wi-Fi watcher.
---
--- Returns:
---
---   * the module object, for method chaining.
---
function obj:stop()
  wifiWatcher:stop()
  isActive = false
  return self
end

--- WifiWatcher:isActive()
---
--- Method
---
--- Returns:
---
---  * A boolean, true if the watcher is active, otherwise false.
---
function obj:isActive()
  return isActive
end

--- WifiWatcher:toggle()
---
--- Method
---
--- Toggles the watcher.
---
--- Returns:
---
---   * the module object, for method chaining.
---
function obj:toggle()
  if isActive then
    wifiWatcher:stop()
  else
    wifiWatcher:start()
  end
  return self
end

function obj:init()
  Settings.set(settingKey, true)
  wifiWatcher = wifi.watcher.new(wifiWatcherCallback)
  return self
end

return obj
