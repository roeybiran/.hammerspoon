local EventTap = require("hs.eventtap")

local obj = {}
obj.modal = nil

local _appObj = nil

obj.actions = {
  nextTab = {
    action = function() EventTap.keyStroke("cmd", "`") end,
    hotkey = {"ctrl", "tab"},
  },
  previousTab = {
    action = function() EventTap.keyStroke({"cmd", "shift"}, "`") end,
    hotkey = {{"ctrl", "shift"}, "tab"}
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
