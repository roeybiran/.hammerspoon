local Host = require("hs.host")
local Plist = require("hs.plist")
local Geometry = require("hs.geometry")
local Eventtap = require("hs.eventtap")
local Timer = require("hs.timer")
local Window = require("hs.window")
local Mouse = require("hs.mouse")

local obj = {}

local cloudSettingsPlistFile = "settings/cloudSettings.plist"

function obj.tableCount(t)
  local n = 0
  for _, _ in pairs(t) do
    n = n + 1
  end
  return n
end

function obj.labelColor()
  if Host.interfaceStyle() == "Dark" then
    return "#FFFFFF"
  else
    return "#000000"
  end
end

function obj.winBackgroundColor()
  if Host.interfaceStyle() == "Dark" then
    return "#262626"
  else
    return "#E7E7E7"
  end
end

function obj.doubleLeftClick(coords, mods, restoring)
  local originalMousePosition
  if restoring then
    originalMousePosition = Mouse.getAbsolutePosition()
  end
  local point = Geometry.point(coords)
  if not mods then
    mods = {}
  end
  local clickState = Eventtap.event.properties.mouseEventClickState
  Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1):setFlags(mods):post()
  Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):setFlags(mods):post()
  Timer.doAfter(
    0.1,
    function()
      Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 2):setFlags(mods):post()
      Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 2):setFlags(mods):post()
      if restoring then
        Mouse.setAbsolutePosition(originalMousePosition)
      end
    end
  )
end

function obj.strictShortcut(keyBinding, app, modal, conditionalFunction, successFunction)
  if (app:bundleID() == Window.focusedWindow():application():bundleID()) then
    local perform = true
    if conditionalFunction ~= nil then
      if not conditionalFunction() then
        perform = false
      end
    end
    if perform then
      successFunction()
    end
  else
    modal:exit()
    Eventtap.keyStroke(table.unpack(keyBinding))
    modal:enter()
  end
end

obj.cloudSettings = {
  get = function(key)
    local rootObject = Plist.read(cloudSettingsPlistFile)
    return rootObject[key]
  end,
  set = function(key, value)
    local rootObject = Plist.read(cloudSettingsPlistFile)
    rootObject[key] = value
    Plist.write(cloudSettingsPlistFile, rootObject)
  end
}

return obj
