local UI = require("rb.ui")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}
local _modal = nil
local _appObj = nil

obj.bundleID = "com.apple.AppStore"

local function goBack(appObj)
  UI.getUIElement(appObj:mainWindow(), {{"AXGroup", 1}, {"AXButton", "AXTitle", "Go Back"}}):performAction("AXPress")
end

local functions = {
  goBack = function()
    goBack(_appObj)
  end,
}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
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
