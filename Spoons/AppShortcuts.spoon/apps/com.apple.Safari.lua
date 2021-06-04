local EventTap = require("hs.eventtap")
local AppleScript = require("hs.osascript").applescript
local KeyCodes = require("hs.keycodes")
local Timer = require("hs.timer")
local FnUtils = require("hs.fnutils")
local Settings = require("hs.settings")
local UI = require("rb.ui")
local Util = require("rb.util")
local AX = require("hs.axuielement")
local DistributedNotifications = require("hs.distributednotifications")
local Observer = AX.observer
local hs = hs

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local obj = {}
local _appObj = nil
local _observer = nil
local layoutsPerURLKey = "RBSafariLayoutsForURL"
local notficationObserver = nil

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
  local addressBarObject = UI.getUIElement(axAppObj, {
    {"AXWindow", "AXMain", true},
    {"AXToolbar", 1}
  }):attributeValue("AXChildren")
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
  local jsFile = script_path() .. "/helpers/navigatePages.js"
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
    UI.getUIElement(appObj, {
      {"AXWindow", 1},
      {"AXSplitGroup", 1},
      {"AXTabGroup", 1},
      {"AXGroup", 1},
      {"AXButton", 1}
    }):performAction("AXPress")
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
  })
  if not firstColumn then
    print("Safari/rightSizeBookmarksOrHistoryColumn: couldn't find the first column")
    return
  end
  local frame = firstColumn:attributeValue("AXFrame")
  local x = frame.x + frame.w
  local y = frame.y + 5
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

local function onReceiveInputSourceChangeNotification()
  local currentLayout = KeyCodes.currentLayout()
  local settingsTable = Settings.get(layoutsPerURLKey) or {}
  local currentURL = getCurrentURL()
  settingsTable[currentURL] = currentLayout
  Settings.set(layoutsPerURLKey, settingsTable)
end

local function onTitleChangeObserverCallback(_, _, _, _)
  local url = getCurrentURL()
  local special = {"bookmarks://", "history://", "favorites://"}
  if FnUtils.contains(special, url) or url == "" or not url then
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

local function setupTitleChangeObserver(appObj)
  local pid = appObj:pid()
  _observer = Observer.new(pid)
  local element = AX.applicationElement(appObj)
  -- if Safari has just been launched, this may return "*accessibility error* (0x60000104cbf8)"
  -- this value is not nil so we need to check by casting
  if not element:asHSApplication() then
    Timer.doAfter(0.5, function()
      if not element then
        hs.showError("AXUIElement still unavailable after delay. Consider increasing the delay's value")
      end
      setupTitleChangeObserver(_appObj)
    end)
    return
  end
  _observer:addWatcher(element, "AXTitleChanged")
  _observer:callback(onTitleChangeObserverCallback)
  _observer:start()
end

obj.modal = nil

obj.actions = {
  --- moveTabLeft - moves the focused tab one position to the left.
  moveTabLeft = {
    action = function()
      moveTab("left")
    end,
    hotkey = {"ctrl", ","}
  },
  --- moveTabRight - moves the focused tab one position to the right.
  moveTabRight = {
    action = function()
      moveTab("right")
    end,
    hotkey = {"ctrl", "."}
  },
  --- newWindow - ensures a new window will be opened rather than a tab. Useful when the "Prefer tabs" setting in the Dock Preference Pane is set to "always".
  newWindow = {
    action = function()
      _appObj:selectMenuItem({"File", "New Window"})
    end,
    hotkey = {"cmd", "n"}
  },
  --- goToNextPage - navigates to a web page's next page, if applicable.
  goToNextPage = {
    action = function()
      pageNavigation("next")
    end,
    hotkey = {"ctrl", "n"}
  },
  --- goToPreviousPage - navigates to a web page's previous page, if applicable.
  goToPreviousPage = {
    action = function()
      pageNavigation("previous")
    end,
    hotkey = {"ctrl", "p"}
  },
  --- moveFocusToMainAreaAndChangeToABCAfterOpeningLocation - unfocuses the address bar (if focused) after loading a web page. Useful when using Vimari's hints feature, which doesn't work with the address bar focused.
  moveFocusToMainAreaAndChangeToABCAfterOpeningLocation = {
    action = function()
      moveFocusToMainAreaAndChangeToABCAfterOpeningLocation(_appObj, obj.modal, {{}, "return"})
    end,
    hotkey = {{}, "return"}
  },
  --- changeToABCAfterFocusingAddressBar - changes the active keyboard layout to ABC once the address bar has gained focus.
  changeToABCAfterFocusingAddressBar = {
    action = function()
      changeToABCAfterFocusingAddressBar(obj.modal, {{"cmd"}, "l"})
    end,
    hotkey = {"cmd", "l"}
  },
  --- TODO
  changeToABCAfterOpeningNewTab = {
    action = function()
      changeToABCAfterFocusingAddressBar(obj.modal, {{"cmd"}, "t"})
    end,
    hotkey = {"cmd", "t"}
  },
  --- newBookmarksFolder - creates a new bookmarks folder. Works only while viewing bookmarks.
  newBookmarksFolder = {
    action = function()
      newBookmarksFolder(_appObj)
    end,
    hotkey = {{"cmd", "shift"}, "n"}
  },
  --- rightSizeBookmarksOrHistoryColumn - sizes to fit the first column of the bookmarks/history view.
  rightSizeBookmarksOrHistoryColumn = {
    action = function()
      rightSizeBookmarksOrHistoryColumn(_appObj)
    end,
    hotkey = {"alt", "r"}
  },
  --- firstSearchResult - in a history/bookmarks view and when the search field is focused, moves focus the 1st search result.
  firstSearchResult = {
    action = function()
      firstSearchResult(_appObj, obj.modal)
    end,
    hotkey = {{}, "tab"}
  }
}

function obj:start(appObj)
  if not notficationObserver then
    notficationObserver = DistributedNotifications.new(onReceiveInputSourceChangeNotification,
    "InputSourceDidChange")
  end
  notficationObserver:start()
  _appObj = appObj
  obj.modal:enter()
  setupTitleChangeObserver(appObj)
  onTitleChangeObserverCallback()
  return self
end

function obj:stop()
  if notficationObserver then
    notficationObserver:stop()
  end
  obj.modal:exit()
  if _observer then
    _observer:stop()
    _observer = nil
  end
  return self
end

return obj
