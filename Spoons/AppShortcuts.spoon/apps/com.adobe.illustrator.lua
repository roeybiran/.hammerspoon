local EventTap = require("hs.eventtap")

local obj = {}
local _appObj = nil

obj.modal = nil

obj.actions = {
  next_tab = {
    action = function() EventTap.keyStroke("cmd", "`") end,
    hotkey = {"ctrl", "tab"},
  },
  previous_tab = {
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
