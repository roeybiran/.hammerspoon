local Geometry = require("hs.geometry")
local Eventtap = require("hs.eventtap")
local Timer = require("hs.timer")
local Window = require("hs.window")
local Mouse = require("hs.mouse")

local obj = {}

function obj.tableCount(t)
  local n = 0
  for _, _ in pairs(t) do
    n = n + 1
  end
  return n
end

function obj.doubleLeftClick(coords, mods, restoring)
  local originalMousePosition
  if restoring then
    originalMousePosition = Mouse.getAbsolutePosition()
  end
  local point = Geometry.point(coords)
  mods = mods or {}
  local clickState = Eventtap.event.properties.mouseEventClickState
  Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1):setFlags(mods)
      :post()
  Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):setFlags(mods)
      :post()
  Timer.doAfter(0.1, function()
    Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 2):setFlags(mods)
        :post()
    Eventtap.event.newMouseEvent(Eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 2):setFlags(mods)
        :post()
    if restoring then
      Mouse.setAbsolutePosition(originalMousePosition)
    end
  end)
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

return obj
