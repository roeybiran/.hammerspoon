local geometry = require("hs.geometry")
local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local timer = require("hs.timer")
local Keycodes = require("hs.keycodes")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "WhatsApp"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local _modal = nil
local _appObj = nil

obj.bundleID = "desktop.WhatsApp"

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
      timer.doAfter(0.4, function() eventtap.keyStroke({}, "tab") end)
    end)
  end)
end

local functions = {switchToABCOnSearch = function() switchToABCOnSearch(_appObj) end}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
      -- print(hs.inspect(v))
      local mods, key = table.unpack(hotkeysTable[k])
      _modal:bind(mods, key, v)
    end
  end
  return self
end

function obj:start(appObj)
  _appObj = appObj
  _modal:enter()
  return self
end

function obj:stop()
  _modal:exit()
  return self
end

function obj:init()
  if not obj.bundleID then
    hs.showError("bundle indetifier for app spoon is nil")
  end
  _modal = Hotkey.modal.new()
  return self
end

return obj
