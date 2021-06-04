local geometry = require("hs.geometry")
local eventtap = require("hs.eventtap")
local KeyCodes = require("hs.keycodes")
local timer = require("hs.timer")
local util = require("rb.util")

local obj = {}
local _appObj = nil

local function whatsAppMouseScripts(appObj, requestedAction)
  local x
  local y
  local frame = appObj:focusedWindow():frame()
  if requestedAction == "AttachFile" then
    x = (frame.x + frame.w - 85)
    y = (frame.y + 30)
  else
    x = (frame.center.x + 80)
    y = (frame.center.y + 30)
  end
  local p = geometry.point({x, y})
  return eventtap.leftClick(p)
end

local function insertGif()
  KeyCodes.setLayout("ABC") -- HEBREW RELATED
  timer.doAfter(0.4, function()
    eventtap.keyStroke({"shift"}, "tab")
    timer.doAfter(0.4, function()
      eventtap.keyStroke({}, "return")
      timer.doAfter(0.4, function()
        eventtap.keyStroke({}, "tab")
      end)
    end)
  end)
end

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
