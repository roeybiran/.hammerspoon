--- === ConfigWatcher ===
---
--- Reload the environment when .lua files in ~/.hammerspoon are modified.

local PathWatcher = require("hs.pathwatcher")
local Settings = require("hs.settings")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "ConfigWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local pathWatcher = nil
local configWatcherActiveKey = "RBConfigWatcherActive"

local function patchWatcherCallbackFn(files, flagTables)
  local doReload = false
  for i, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      if flagTables[i].itemModified or flagTables[i].itemCreated or flagTables[i].itemRenamed then
        doReload = true
        break
      end
    end
  end
  if doReload then
    if Settings.get(configWatcherActiveKey) then
      hs.reload()
    end
  end
end

--- ConfigWatcher.toggle()
---
--- Method
---
--- Toggles the module.
---
function obj.toggle()
  if pathWatcher then
    obj.stop()
  else
    obj.start()
  end
end

--- ConfigWatcher.stop()
---
--- Method
---
--- Stops the module.
---
function obj.stop()
  Settings.set(configWatcherActiveKey, false)
  pathWatcher:stop()
  pathWatcher = nil
end

--- ConfigWatcher.start()
---
--- Method
---
--- Starts the module.
---
function obj.start()
  Settings.set(configWatcherActiveKey, true)
  if not pathWatcher then
    obj.init()
  end
  pathWatcher:start()
end

--- ConfigWatcher.isActive()
---
--- Method
---
--- Returns:
---
---  * A boolean, true if the module is active, otherwise false
---
function obj.isActive()
  return pathWatcher ~= nil
end

function obj.init()
  pathWatcher = PathWatcher.new(".", patchWatcherCallbackFn)
end

return obj
