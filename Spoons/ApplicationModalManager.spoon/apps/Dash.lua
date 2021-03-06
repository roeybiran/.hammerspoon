local Hotkey = require("hs.hotkey")
local ui = require("rb.ui")

local obj = {}
local _modal = nil
local _appObj = nil

obj.bundleID = "com.kapeli.dashdoc"

local function pane1(appObj)
  local _pane1 = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}}
  ui.getUIElement(appObj, _pane1):setAttributeValue("AXFocused", true)
end

local function pane2(appObj)
  local _pane2 = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXGroup", 1}, {"AXGroup", 1}, {"AXScrollArea", 1}}
  ui.getUIElement(appObj, _pane2):setAttributeValue("AXFocused", true)
end

local function clickOnHistoryMenuItem(appObj)
  appObj:selectMenuItem({"History"})
end

local function toggleBookmarks(appObj)
  if appObj:selectMenuItem({"Bookmarks", "Show Bookmarks..."}) then
    return
  end
  appObj:selectMenuItem({"Bookmarks", "Hide Bookmarks"})
end

local functions = {
  pane1 = function()
    pane1(_appObj)
  end,
  pane2 = function()
    pane2(_appObj)
  end,
  clickOnHistoryMenuItem = function()
    clickOnHistoryMenuItem(_appObj)
  end,
  toggleBookmarks = function()
    toggleBookmarks(_appObj)
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
