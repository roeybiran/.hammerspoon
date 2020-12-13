local ui = require("rb.ui")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Reminders"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local _modal = nil
local _appObj = nil

obj.bundleID = "com.apple.reminders"

local function pane1(appObj)
  local pane1element = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXLayoutArea", 1}, {"AXScrollArea", 1}}
  ui.getUIElement(appObj, pane1element):setAttributeValue("AXFocused", true)
end

local function pane2(appObj)
  local pane2element = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXLayoutArea", 2}, {"AXScrollArea", 1}}
  ui.getUIElement(appObj, pane2element):setAttributeValue("AXFocused", true)
end

local functions = {pane1 = function() pane1(_appObj) end, pane2 = function() pane2(_appObj) end}

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
