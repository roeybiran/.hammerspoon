local ui = require("rb.ui")

local obj = {}
local _appObj = nil

local function focusFilterField(appObj)
  local filterField = ui.getUIElement(appObj, {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXTextField", 1}})
  if not filterField then
    appObj:selectMenuItem({"View", "Show Filter Field"})
  else
    filterField:setAttributeValue("AXFocused", true)
  end
end

obj.modal = nil

obj.actions = {
  focusFilterField = {
    action = function() focusFilterField(_appObj) end,
    hotkey = {"cmd", "l"}
  }
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
