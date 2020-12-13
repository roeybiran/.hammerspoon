local EventTap = require("hs.eventtap")
local ui = require("rb.ui")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Dictionary"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local _modal = nil
local _appObj = nil
obj.bundleID = "com.apple.Dictionary"

local function pane1(appObj)
  local pane1A = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}, {"AXList", 1}}
  local pane1B = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}, {"AXTable", 1}}
  local t = ui.getUIElement(appObj, pane1A)
  if not t then
    t = ui.getUIElement(appObj, pane1B)
  end
  t:setAttributeValue("AXFocused", true)
end

local function pane2(appObj)
  local _pane2 = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 2}, {"AXScrollArea", 1}, {"AXWebArea", 1}}
  ui.getUIElement(appObj, _pane2):setAttributeValue("AXFocused", true)
end

local function newWindow(modal)
  modal:exit()
  EventTap.keyStroke({"cmd", "alt"}, "n")
  modal:enter()
end

local functions = {
  pane1 = function() pane1(_appObj) end,
  pane2 = function() pane2(_appObj) end,
  newWindow = function() newWindow(_appObj) end,
}

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
