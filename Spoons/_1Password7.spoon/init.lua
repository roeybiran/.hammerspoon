--- === 1Password ===
---
--- 1Password automations.
local Hotkey = require("hs.hotkey")
local ui = require("rb.ui")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "1Password7"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.bundleID = "com.agilebits.onepassword7"

local _modal = nil
local _appObj = nil

local function toggleCategories(appObj, category)
  -- possible values for category:
  -- WATCHTOWER, CATEGORIES, TAGS
  local cell
  local buttonTitle
  local child2
  local sidebarRows = ui.getUIElement(appObj,
                                      {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}, {"AXOutline", 1}})
  sidebarRows = sidebarRows:attributeValue("AXChildren")
  for _, row in ipairs(sidebarRows) do
    if row:attributeValue("AXRole") == "AXRow" then
      cell = row:attributeValue("AXChildren")[1]
      child2 = cell:attributeValue("AXChildren")[2]
      if child2 ~= nil then
        if child2:attributeValue("AXRole") == "AXButton" then
          buttonTitle = cell:attributeValue("AXChildren")[1]:attributeValue("AXValue")
          if buttonTitle == category then
            child2:performAction("AXPress")
            return
          end
        end
      end
    end
  end
end

local function sortBy(appObj)
  local sortByButton = {
    {"AXWindow", 1},
    {"AXSplitGroup", 1},
    {"AXSplitGroup", 1},
    {"AXGroup", 1},
    {"AXUnknown", 2},
    {"AXMenuButton", 1}
  }
  ui.getUIElement(appObj, sortByButton):performAction("AXPress")
end

local function pane1(appObj)
  local _pane1 = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}}
  ui.getUIElement(appObj, _pane1):setAttributeValue("AXFocused", true)
end

local function pane2(appObj)
  local _pane2 = {
    {"AXWindow", 1},
    {"AXSplitGroup", 1},
    {"AXSplitGroup", 1},
    {"AXGroup", 1},
    {"AXScrollArea", 1},
    {"AXTable", 1}
  }
  ui.getUIElement(appObj, _pane2):setAttributeValue("AXFocused", true)
end

local functions = {pane1 = function() pane1(_appObj) end, pane2 = function() pane2(_appObj) end}

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
