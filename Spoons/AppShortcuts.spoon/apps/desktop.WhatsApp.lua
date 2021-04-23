local geometry = require("hs.geometry")
local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local timer = require("hs.timer")
local Keycodes = require("hs.keycodes")

local obj = {}
obj.modal = nil

local _appObj = nil

local function switchToABCOnSearch(appObj)
  Keycodes.setLayout("ABC")
  appObj:selectMenuItem({"Edit", "Search"})
end

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
  keycodes.setLayout("ABC") -- HEBREW RELATED
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

local functions = {
  switchToABCOnSearch = function()
    switchToABCOnSearch(_appObj)
  end,
}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
      -- print(hs.inspect(v))
      local mods, key = table.unpack(hotkeysTable[k])
      obj.modal:bind(mods, key, v)
    end
  end
  return self
end

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
