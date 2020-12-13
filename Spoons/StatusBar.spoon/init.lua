--- === StatusBar ===
---
--- Enables a status menu item with the familiar Hammerspoon logo, but with customizable contents and a flashing mode to signal ongoing operations.

local HSApplication = require("hs.application")
local HSMenubar = require("hs.menubar")
local HSTimer = require("hs.timer")
local HSURLEvent = require("hs.urlevent")
local spoon = spoon

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local obj = {}

obj.__index = obj
obj.name = "StatusBar"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local menuBarItem
local spoonPath = script_path()
local regularIconPath = spoonPath .. "/statusicon.pdf"
local fadedIconPath = spoonPath .. "/statusicon_faded.pdf"
local current = "regular"
local flashingIconTimer
local taskQueue = 0

-- StatusBar.menuTable
-- Variable
-- **TODO**
obj.menuTable = nil

-- StatusBar:addTask()
-- Method
-- **TODO**
function obj:addTask()
  if not flashingIconTimer:running() then
    flashingIconTimer:start()
  end
  taskQueue = taskQueue + 1
  return self
end

-- StatusBar:removeTask()
-- Method
-- **TODO**
function obj:removeTask()
  taskQueue = taskQueue - 1
  if taskQueue < 1 then
    menuBarItem:setIcon(regularIconPath)
    flashingIconTimer:stop()
  end
  return self
end

function obj:start()
  obj.menuTable = {
    {
      title = "Watch for config changes",
      fn = function()
        spoon.ConfigWatcher:toggle()
      end,
      checked = spoon.ConfigWatcher:isActive()
    },
    {
      title = "Watch for appearance changes",
      fn = function()
        spoon.AppearanceWatcher:toggle()
      end,
      checked = spoon.AppearanceWatcher:isActive()
    },
    {
      title = "Mute on unknown networks",
      fn = function()
        spoon.WifiWatcher:toggle()
      end,
      checked = spoon.WifiWatcher:isActive()
    },
    {title = "-"},
    {
      title = "Quit Hammerspoon",
      fn = function()
        HSApplication("Hammerspoon"):kill()
      end
    }
  }
  menuBarItem = HSMenubar.new():setIcon(regularIconPath):setMenu(obj.menuTable)
  flashingIconTimer =
    HSTimer.new(
    0.2,
    function()
      if current == "regular" then
        menuBarItem:setIcon(regularIconPath)
        current = "faded"
      else
        menuBarItem:setIcon(fadedIconPath)
        current = "regular"
      end
    end
  )
  HSURLEvent.bind(
    "start-task-with-progress",
    function()
      obj:addTask()
    end
  )
  HSURLEvent.bind(
    "stop-task-with-progress",
    function()
      obj:removeTask()
    end
  )
  return self
end

return obj
