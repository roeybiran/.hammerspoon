local ax = require("hs.axuielement")
local ui = require("rb.ui")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Contacts"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local _modal = nil
local _appObj = nil

obj.bundleID = 'com.apple.AddressBook'

local function performContactAction(appObj, button)
  local win = ax.windowElement(appObj:focusedWindow())
  local btn = ui.getUIElement(win, {
    {'AXSplitGroup', 1},
    {'AXButton', button}
  })
  btn:performAction('AXPress')
end

local functions = {
  contactAction1 = function() performContactAction(_appObj, 4) end,
  contactAction2 = function() performContactAction(_appObj, 5) end,
  contactAction3 = function() performContactAction(_appObj, 6) end,
  contactAction4 = function() performContactAction(_appObj, 7) end,
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
