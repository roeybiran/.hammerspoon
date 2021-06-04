local ax = require("hs.axuielement")
local ui = require("rb.ui")

local obj = {}
local _appObj = nil

local function performContactAction(appObj, button)
  local win = ax.windowElement(appObj:focusedWindow())
  local btn = ui.getUIElement(win, {{"AXSplitGroup", 1}, {"AXButton", button}})
  btn:performAction("AXPress")
end

obj.modal = nil

obj.actions = {
  contactAction1 = {
    action = function() performContactAction(_appObj, 4) end,
    hotkey = {"cmd", "1"}
  },
  contactAction2 = {
    action = function() performContactAction(_appObj, 5) end,
    hotkey = {"cmd", "2"}
  },
  contactAction3 = {
    action = function() performContactAction(_appObj, 6) end,
    hotkey = {"cmd", "3"}
  },
  contactAction4 = {
    action = function() performContactAction(_appObj, 7) end,
    hotkey = {"cmd", "4"}
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
