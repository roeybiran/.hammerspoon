local ax = require("hs.axuielement")
local ui = require("util.ax")

local obj = {}
local _appObj = nil

local function clickActivityMonitorRadioButton(appObj, aButton)
  ui.getUIElement(ax.windowElement(appObj:mainWindow()), {
    {"AXToolbar", 1},
    {"AXGroup", 2},
    {"AXRadioGroup", 1},
    {"AXRadioButton", tonumber(aButton)}
  }):performAction("AXPress")
end

obj.modal = nil

obj.actions = {
  radioButton1 = {
    action = function() clickActivityMonitorRadioButton(_appObj, 1) end,
    hotkey = {"cmd", "1"},
  },
  radioButton2 = {
    action = function() clickActivityMonitorRadioButton(_appObj, 2) end,
    hotkey = {"cmd", "2"},
  },
  radioButton3 = {
    action = function() clickActivityMonitorRadioButton(_appObj, 3) end,
    hotkey = {"cmd", "3"},
  },
  radioButton4 = {
    action = function() clickActivityMonitorRadioButton(_appObj, 4) end,
    hotkey = {"cmd", "4"},
  },
  radioButton5 = {
    action = function() clickActivityMonitorRadioButton(_appObj, 5) end,
    hotkey = {"cmd", "5"},
  },
  quitProcess = {
    action = function() _appObj:selectMenuItem({"View", "Quit Process"}) end,
    hotkey = {"cmd", "delete"}
  },
}

function obj:start(appObj)
  _appObj = appObj
  obj.modal:enter()
  return self
end

function obj:stop()
  obj.modal:exit()
  return self
end

return obj
