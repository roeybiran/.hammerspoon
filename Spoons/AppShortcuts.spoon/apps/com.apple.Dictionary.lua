local EventTap = require("hs.eventtap")

local obj = {}
local _appObj = nil

local function newWindow(modal)
  modal:exit()
  EventTap.keyStroke({"cmd", "alt"}, "n")
  modal:enter()
end

obj.modal = nil

obj.actions = {
  newWindow = {
    action = function() newWindow(_appObj) end,
    hotkey = {"cmd", "n"}
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
