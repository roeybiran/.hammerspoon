--- === AppearanceWatcher ===
---
--- Perform actions when the system's theme changes. Actions can be configured by editing the shell script inside the Spoon's directory.

local task = require("hs.task")
local settings = require("hs.settings")
local PathWatcher = require("hs.pathwatcher")
local Host = require("hs.host")

local obj = {}

obj.__index = obj
obj.name = "AppearanceWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local watcher
local appearanceWatcherActiveKey = "RBAppearanceWatcherIsActive"
local cachedInterfaceStyleKey = "RBAppearanceWatcherCachedInterfaceStyle"
local appearancePlist = os.getenv("HOME") .. "/Library/Preferences/.GlobalPreferences.plist"

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local function setStyle()
  local currentSystemStyle = Host.interfaceStyle() or "Light"
  local cachedStyle = settings.get(cachedInterfaceStyleKey)
  if currentSystemStyle ~= cachedStyle then
    local msg = string.format("AppearanceWatcher: detected a system style change, from %s to %s", cachedStyle, currentSystemStyle)
    print(msg)
    if settings.get(appearanceWatcherActiveKey) == false then
      return
    end
    settings.set(cachedInterfaceStyleKey, currentSystemStyle)
    task.new(
      script_path() .. "/appearance.sh",
      function(exitCode, stdOut, stdErr)
        if exitCode > 0 then
          msg = string.format([[AppearanceWatcher: appearance.sh exited with non-zero exit code (%s). stdout: %s, stderr: %s]], exitCode, stdOut, stdErr)
          print(msg)
        end
      end,
      {currentSystemStyle:lower()}
    ):start()
  end
end

function obj.init()
  watcher =
    PathWatcher.new(
    appearancePlist,
    function()
      setStyle()
    end
  )
end

--- AppearanceWatcher:stop()
---
--- Method
---
--- Stops this module.
---
function obj.stop()
  watcher:stop()
  watcher = nil
  settings.set(appearanceWatcherActiveKey, false)
end

--- AppearanceWatcher:start()
---
--- Method
---
--- starts this module.
---
function obj.start()
  if not watcher then
    obj.init()
  end
  watcher:start()
  setStyle()
  settings.set(appearanceWatcherActiveKey, true)
end

--- AppearanceWatcher:toggle()
---
--- Method
---
--- Toggles this module.
---
function obj.toggle()
  if obj:isActive() then
    obj.stop()
  else
    obj.start()
  end
end

--- AppearanceWatcher:isActive()
---
--- Method
---
--- Determines whether module is active.
---
--- Returns:
---
---  * A boolean, true if the module's watcher is active, otherwise false
---
function obj.isActive()
  return watcher ~= nil
end

return obj
