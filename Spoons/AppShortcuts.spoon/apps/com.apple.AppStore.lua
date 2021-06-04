local UI = require("rb.ui")

local obj = {}
local _appObj = nil

local function goBack(appObj)
  for _, option in ipairs({"AXToolbar", "AXGroup"}) do
    local element = UI.getUIElement(appObj:mainWindow(), {{option, 1}, {"AXButton", "AXTitle", "Go Back"}})
    if element then
      element:performAction("AXPress")
      return
    end
  end
end

obj.modal = nil

obj.actions = {
  goBack = {
    action = function() goBack(_appObj) end,
    goBack = {"cmd", "["}
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
