--- === Safari ===
---
--- Safari automations.
---
local EventTap = require("hs.eventtap")
local AppleScript = require("hs.osascript").applescript
local KeyCodes = require("hs.keycodes")
local Timer = require("hs.timer")
local Hotkey = require("hs.hotkey")
local FnUtils = require("hs.fnutils")
local Settings = require("hs.settings")
local UI = require("rb.ui")
local Util = require("rb.util")
local AX = require("hs.axuielement")
local Observer = AX.observer
local hs = hs

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local obj = {}

obj.__index = obj
obj.name = "Safari"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.bundleID = "com.apple.Safari"

local _modal = nil
local _appObj = nil
local _observer = nil
local layoutsPerURLKey = "RBSafariLayoutsForURL"

local function moveFocusToSafariMainArea(appObj, includeSidebar)
  -- ui scripting notes:
  -- when the status bar overlay shows, it's the first window. you should look for the "Main" window instead.
  -- "pane1" = is either the main web area, or the sidebar
  local sidebar = {
    {"AXWindow", "AXRoleDescription", "standard window"},
    {"AXSplitGroup", 1},
    {"AXGroup", 1},
    {"AXScrollArea", 1},
    {"AXOutline", 1}
  }
  local bookmarksAndHistoryView = {
    {"AXWindow", "AXRoleDescription", "standard window"},
    {"AXSplitGroup", 1},
    {"AXTabGroup", 1},
    {"AXGroup", 1},
    {"AXScrollArea", 1},
    {"AXOutline", 1}
  }
  local standardWebpageView = {
    {"AXWindow", "AXRoleDescription", "standard window"},
    {"AXSplitGroup", 1},
    {"AXTabGroup", 1},
    {"AXGroup", 1},
    {"AXGroup", 1},
    {"AXScrollArea", 1},
    {"AXWebArea", 1}
  }
  local targetPane
  local sideBar
  local webArea = UI.getUIElement(appObj, standardWebpageView)
  local bookmarksOrHistory = UI.getUIElement(appObj, bookmarksAndHistoryView)
  if includeSidebar then
    sideBar = UI.getUIElement(appObj, sidebar)
  end
  if sideBar then
    targetPane = sideBar
  elseif webArea then
    targetPane = webArea
  elseif bookmarksOrHistory then
    targetPane = bookmarksOrHistory
  end
  targetPane:setAttributeValue("AXFocused", true)
end

local function isSafariAddressBarFocused(appObj)
  local axAppObj = AX.applicationElement(appObj)
  local addressBarObject = UI.getUIElement(axAppObj, {{"AXWindow", "AXMain", true}, {"AXToolbar", 1}}):attributeValue(
                               "AXChildren")
  for _, toolbarObject in ipairs(addressBarObject) do
    local toolbarObjectsChilds = toolbarObject:attributeValue("AXChildren")
    if toolbarObjectsChilds then
      for _, toolbarObjectChild in ipairs(toolbarObjectsChilds) do
        if toolbarObjectChild:attributeValue("AXRole") == "AXTextField" then
          return (toolbarObjectChild:attributeValue("AXFocused") == true)
        end
      end
    end
  end
end

local function changeToABCAfterFocusingAddressBar(modal, keystroke)
  if KeyCodes.currentLayout() == "Hebrew" then
    KeyCodes.setLayout("ABC")
  end
  modal:exit()
  EventTap.keyStroke(table.unpack(keystroke))
  modal:enter()
end

local function moveFocusToMainAreaAndChangeToABCAfterOpeningLocation(appObj, modal, keystroke)
  local isFocused = isSafariAddressBarFocused(appObj)
  modal:exit()
  EventTap.keyStroke(table.unpack(keystroke))
  modal:enter()
  -- if the address bar wasn't focused, it's a regular return press. bail out
  if not isFocused then
    return
  end
  -- KeyCodes.setLayout("ABC")
  local UIElementHomeScreenView = {
    {"AXWindow", "AXRoleDescription", "standard window"},
    {"AXSplitGroup", 1},
    {"AXTabGroup", 1},
    {"AXScrollArea", 1}
  }
  -- in my experience, the address bar remains focused only after searching in Google
  -- so, wait an initial interval before entering loop
  Timer.doAfter(0.3, function()
    if not isSafariAddressBarFocused(appObj) then
      return
    end
    for _ = 1, 3 do
      Timer.doAfter(0.3, function()
        if isSafariAddressBarFocused(appObj) then
          local welcomePageIsDisplayed = UI.getUIElement(appObj, UIElementHomeScreenView) ~= nil
          if not welcomePageIsDisplayed then
            moveFocusToSafariMainArea(appObj, true)
          end
        end
      end)
    end
  end)

end

local function pageNavigation(direction)
  local jsFile = script_path() .. "/navigatePages.js"
  local script = [[
  set _arg to "%s"
  set theFile to (POSIX file "%s" as alias)
  set theScript to read theFile as string
  set theScript to "var direction = '" & _arg & "'; " & theScript
  tell application "Safari"
  tell (window 1 whose visible of it = true)
  tell (tab 1 whose visible of it = true)
  return do JavaScript theScript
  end tell
end tell
end tell
]]
  script = string.format(script, direction, jsFile)
  AppleScript(script)
end

local function newBookmarksFolder(appObj)
  local title = appObj:focusedWindow():title()
  if string.match(title, "Bookmarks") then
    UI.getUIElement(appObj, {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXTabGroup", 1}, {"AXGroup", 1}, {"AXButton", 1}}):performAction(
        "AXPress")
  else
    appObj:selectMenuItem({"File", "New Private Window"})
  end
end

local function rightSizeBookmarksOrHistoryColumn(appObj)
  local firstColumn = UI.getUIElement(appObj, {
    {"AXWindow", 1},
    {"AXSplitGroup", 1},
    {"AXTabGroup", 1},
    {"AXGroup", 1},
    {"AXScrollArea", 1},
    {"AXOutline", 1},
    {"AXGroup", 1},
    {"AXButton", "AXTitle", "Website"}
  }):attributeValue("AXFrame")
  local x = firstColumn.x + firstColumn.w
  local y = firstColumn.y + 5
  Util.doubleLeftClick({x, y})
end

local function firstSearchResult(appObj, modal)
  -- moves focus to the bookmarks/history list
  local title = appObj:focusedWindow():title()
  -- if we're in the history or bookmarks windows
  if title:match("Bookmarks") or title:match("History") then
    local axApp = AX.applicationElement(appObj)
    -- if search field is focused
    if axApp:attributeValue("AXFocusedUIElement"):attributeValue("AXSubrole") == "AXSearchField" then
      return moveFocusToSafariMainArea(appObj, false)
    end
  end
  modal:exit()
  EventTap.keyStroke({}, "tab")
  modal:enter()
end

local function moveTab(direction)
  local args
  if direction == "right" then
    args = {"+", "1", "before", "after"}
  else
    args = {"-", "(index of last tab)", "after", "before"}
  end
  local script = [[
  tell application "Safari"
  tell window 1
  set sourceIndex to index of current tab
  set targetIndex to (sourceIndex %s 1)
  if not (exists tab targetIndex) then
    set targetIndex to %s
    move tab sourceIndex to %s tab targetIndex
  end if
  move tab sourceIndex to %s tab targetIndex
  set current tab to tab targetIndex
end tell
end tell
]]
  script = string.format(script, table.unpack(args))
  AppleScript(script)
end

local function getCurrentURL()
  -- AppleScript method
  local _, currentURL, _ = AppleScript [[
  tell application "Safari"
    tell window 1
      return URL of current tab
    end tell
  end tell]]
  if not currentURL then
    return
  end
  currentURL = currentURL:gsub("^.+://", "")
  local lastSlash = currentURL:find("/")
  if lastSlash then
    currentURL = currentURL:sub(1, lastSlash - 1)
  end
  return currentURL
end

local function setLayoutForURL(_, _, _, _)
  local url = getCurrentURL()
  local special = {"bookmarks://", "history://", "favorites://"}
  if not url or url == "" or FnUtils.contains(special, url) then
    KeyCodes.setLayout("ABC")
    return
  end
  local newLayout = "ABC"
  local settingsTable = Settings.get(layoutsPerURLKey) or {}
  local urlSetting = settingsTable[url]
  if urlSetting then
    newLayout = urlSetting
  end
  KeyCodes.setLayout(newLayout)
end

local function addObserver(appObj)
  local pid = appObj:pid()
  _observer = Observer.new(pid)
  local element = AX.applicationElement(appObj)
  _observer:addWatcher(element, "AXTitleChanged")
  _observer:callback(setLayoutForURL)
  _observer:start()
  setLayoutForURL()
end

local functions = {
  moveTabLeft = function() moveTab("left") end,
  moveTabRight = function() moveTab("right") end,
  newWindow = function() _appObj:selectMenuItem({"File", "New Window"}) end,
  goToNextPage = function() pageNavigation("next") end,
  goToPreviousPage = function() pageNavigation("previous") end,
  moveFocusToMainAreaAndChangeToABCAfterOpeningLocation = function()
    moveFocusToMainAreaAndChangeToABCAfterOpeningLocation(_appObj, _modal, {{}, "return"})
  end,
  changeToABCAfterFocusingAddressBar = function() changeToABCAfterFocusingAddressBar(_modal, {{"cmd"}, "l"}) end,
  focusSidebar = function() moveFocusToSafariMainArea(_appObj, true) end,
  focusMainArea = function() moveFocusToSafariMainArea(_appObj, false) end,
  newBookmarksFolder = function() newBookmarksFolder(_appObj) end,
  rightSizeBookmarksOrHistoryColumn = function() rightSizeBookmarksOrHistoryColumn(_appObj) end,
  firstSearchResult = function() firstSearchResult(_appObj, _modal) end
}

--- _Safari:bindModalHotkeys(hotkeysTable)
---
--- Method
---
--- Parameters:
---
--- * `hotkeysTable` - A table of key value pairs. The hotkeys to be toggled when the target app activates.
---   * Each value is a table (as per the `hs.hotkey.bind` constructor) defining the hotkey of choice.
---   * Each key is the name of the function to be executed by the hotkey.
---   * No hotkeys are bound by default. Leave as is to disable.
---
--- This module offers the following functionalities:
---
--- * `moveTabLeft` - moves the focused tab one position to the left.
--- * `moveTabRight` - moves the focused tab one position to the right.
--- * `newWindow` - ensures a new window will be opened rather than a tab. Useful when the "Prefer tabs" setting in the Dock Preference Pane is set to "always".
--- * `goToNextPage` - navigates to a web page's next page, if applicable.
--- * `goToPreviousPage` - navigates to a web page's previous page, if applicable.
--- * `moveFocusToMainAreaAndChangeToABCAfterOpeningLocation` - unfocuses the address bar (if focused) after loading a web page. Useful when using Vimari's hints feature, which doesn't work with the address bar focused.
--- * `changeToABCAfterFocusingAddressBar` - changes the active keyboard layout to ABC once the address bar has gained focus.
--- * `focusSidebar` - focuses the side bar.
--- * `focusMainArea` - focuses the main area, that is, the web page.
--- * `newBookmarksFolder` - creates a new bookmarks folder. Works only while viewing bookmarks.
--- * `rightSizeBookmarksOrHistoryColumn` - sizes to fit the first column of the bookmarks/history view.
--- * `firstSearchResult` - in a history/bookmarks view and when the search field is focused, moves focus the 1st search result.
---
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

function obj:saveLayoutForCurrentURL(newLayout)
  local settingsTable = Settings.get(layoutsPerURLKey) or {}
  local currentURL = getCurrentURL()
  settingsTable[currentURL] = newLayout
  Settings.set(layoutsPerURLKey, settingsTable)
  return self
end

function obj:start(appObj)
  _appObj = appObj
  _modal:enter()
  addObserver(appObj)
  return self
end

function obj:stop()
  _modal:exit()
  if _observer then
    _observer:stop()
    _observer = nil
  end
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

-- local function showNavMenus(appObj, direction)
--   local button
--   if direction == "forward" then
--     button = 2
--   else
--     button = 1
--   end
--   UI.getUIElement(appObj:mainWindow(), {{"AXToolbar", 1}, {"AXGroup", 1}, {"AXButton", button}}):performAction("AXShowMenu")
-- end

-- local function savePageAsPDF()
--   AppleScript([[
--     tell application "System Events"
--       tell process "Safari"
--         tell menu bar 1
--           tell menu bar item "File"
--             tell menu 1
--               click (first menu item whose title contains "Print")
--             end tell
--           end tell
--         end tell
--         tell window 1
--           repeat until sheet 1 exists
--           end repeat
--           tell sheet 1
--             click menu button 1 -- "PDF"
--             delay 0.2
--             tell menu button 1
--               tell menu 1
--                 click menu item "Save as PDF"
--               end tell
--             end tell
--           end tell
--         end tell
--       end tell
--     end tell]])
-- end
