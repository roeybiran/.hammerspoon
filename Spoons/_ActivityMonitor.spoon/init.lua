--- === ActivityMonitor ===
---
--- Activity Monitor.app automations.
local Hotkey = require("hs.hotkey")
local ax = require("hs.axuielement")
local ui = require("rb.ui")
local hs = hs

local obj = {}
local _modal = nil
local _appObj = nil

obj.__index = obj
obj.name = "ActivityMonitor"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.bundleID = "com.apple.ActivityMonitor"

local function clickActivityMonitorRadioButton(appObj, aButton)
  ui.getUIElement(ax.windowElement(appObj:mainWindow()),
                  {{"AXToolbar", 1}, {"AXGroup", 2}, {"AXRadioGroup", 1}, {"AXRadioButton", tonumber(aButton)}}):performAction(
      "AXPress")
end

local functions = {
  radioButton1 = function() clickActivityMonitorRadioButton(_appObj, 1) end,
  radioButton2 = function() clickActivityMonitorRadioButton(_appObj, 2) end,
  radioButton3 = function() clickActivityMonitorRadioButton(_appObj, 3) end,
  radioButton4 = function() clickActivityMonitorRadioButton(_appObj, 4) end,
  radioButton5 = function() clickActivityMonitorRadioButton(_appObj, 5) end,
  quitProcess = function() _appObj:selectMenuItem({"View", "Quit Process"}) end
}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
      -- print(hs.inspect(v))
      local mods, key = table.unpack(hotkeysTable[k])
      _modal:bind(mods, key, v)
    end
  end
  return self
end

function obj:start(appObj)
  _appObj = appObj
  _modal:enter()
  return self
end

function obj:stop()
  _modal:exit()
  return self
end

function obj:init()
  if not obj.bundleID then
    hs.showError("bundle indetifier for app spoon is nil")
  end
  _modal = Hotkey.modal.new()
  return self
end

return obj
