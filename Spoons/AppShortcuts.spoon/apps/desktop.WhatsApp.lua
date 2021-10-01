local KeyCodes = require("hs.keycodes")
local util = require("rb.util")

local obj = {}
local _appObj = nil

obj.modal = nil

obj.actions = {
  switchToABCOnSearch = {
    action = function() util:passthroughShortcut(
      {"cmd", "f"},
      obj.modal,
      function() KeyCodes.setLayout("ABC") end)
    end,
    hotkey = {"cmd", "f"},
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
