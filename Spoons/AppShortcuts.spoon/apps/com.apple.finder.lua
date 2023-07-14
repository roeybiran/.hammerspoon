local eventtap = require("hs.eventtap")
local geometry = require("hs.geometry")
local osascript = require("hs.osascript")
local timer = require("hs.timer")
local ax = require("hs.axuielement")
local ui = require("util.ax")
local Util = require("util.util")
local GlobalChooser = require("util.fuzzychooser")
local FNUtils = require("hs.fnutils")

local obj = {}
local _appObj = nil

local function getFinderSelection()
  local _, selection, _ = osascript.applescript([[
  set theSelectionPOSIX to {}
  tell application "Finder" to set theSelection to selection as alias list
  repeat with i from 1 to count theSelection
    set end of theSelectionPOSIX to (POSIX path of item i of theSelection)
  end repeat
    set {saveTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {linefeed}}
    return theSelectionPOSIX as text
    set AppleScript's text item delimiters to saveTID
    ]])
    if not selection then
      return
    end
    selection = FNUtils.split(selection, "\n")
    if next(selection) == nil then
      return nil
    else
      return selection
    end
  end

  local function browseInLaunchBar()
    osascript.applescript([[
    ignoring application responses
    tell application "LaunchBar" to perform action "Browse Current Folder"
  end ignoring]])
end

local function newWindow(modal)
  modal:exit()
  eventtap.keyStroke({"cmd", "alt"}, "n")
  modal:enter()
end

local function rightSizeColumn(appObj, arg)
  -- right-size the first column in list view, or the 'active' column in columns view
  -- for columns view: if arg is "all", right sizes all columns indivdually; if arg is "this", right sizes just the 'focused' column
  -- for list view, arg is ignored and the first column (usually 'name') is resized
  -- if current view is list view, or if current view is columns view (and arg is "this"): double click divider
  -- if currnet view is columns view and arg is "all": double click divider with option down
  -- getting the current view from Finder
  local _, currentView, _ = osascript.applescript("tell application \"Finder\" to return current view of window 1")
  local axApp = ax.applicationElement(appObj)
  local x, y, coords, modifiers
  -- for columns view:
  -- focusedElement is a selected Finder item, its parent will be the "active" scroll area
  -- we'll get the position of the column-resize icon based on the selected scroll area's AXFrame
  -- each scroll area represents a Finder column (scroll area 1 = column 1...)
  if currentView == "clvw" then
    coords = axApp:attributeValue("AXFocusedUIElement"):attributeValue("AXParent"):attributeValue("AXFrame")
    x = (coords.x + coords.w) - 10
    y = (coords.y + coords.h) - 10
  elseif currentView == "lsvw" then
    -- for list view, `arg` is ignored
    arg = "this"
    local firstColumn = ui.getUIElement(appObj, {
      {"AXWindow", 1},
      {"AXSplitGroup", 1},
      {"AXSplitGroup", 1},
      {"AXScrollArea", 1},
      {"AXOutline", 1},
      {"AXGroup", 1},
      {"AXButton", 1},
    })
    coords = firstColumn:attributeValue("AXFrame")
    x = coords.x + coords.w
    y = coords.y + (coords.h / 2)
  end
  local point = geometry.point({x, y})
  if arg == "this" then
    modifiers = nil
  elseif arg == "all" then
    modifiers = {alt = true}
  end
  Util.doubleLeftClick(point, modifiers, true)
end

local function undoCloseTab()
  osascript.applescript([[
  tell application "Default Folder X" to set recentFinderWindows to GetRecentFinderWindows
  tell application "Finder" to set currentFinderWindows to every Finder window
  repeat with i from 1 to count recentFinderWindows
    set recentFinderWindowAsText to (item i of recentFinderWindows as text)
    if not my recentWindowIsCurrentlyOpen(recentFinderWindowAsText, currentFinderWindows) then
      set recentWindowAsPosix to POSIX path of item i of recentFinderWindows
      return do shell script "/usr/bin/open" & space & quoted form of recentWindowAsPosix
      end if
    end repeat

      on recentWindowIsCurrentlyOpen(recentFinderWindowAsText, currentFinderWindows)
      tell application "Finder"
      -- skip non existent items
      if not (exists alias recentFinderWindowAsText) then return true
        repeat with i from 1 to count currentFinderWindows
          set currentFinderWindow to item i of currentFinderWindows
          set currentFinderWindowAsAlias to (target of currentFinderWindow as alias)
          set currentFinderWindowAsText to (currentFinderWindowAsAlias as text)
          -- if tab is open but not the first tab, switch to it
          if recentFinderWindowAsText = currentFinderWindowAsText then
            return true
          end if
        end repeat
          return false
        end tell
      end recentWindowIsCurrentlyOpen
      ]])
    end

    local function getMainArea(appObj)
      -- the last common ancestors to all finder views
      local mainArea = ui.getUIElement(appObj, {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXSplitGroup", 1}})
      -- column view: axbrowser 1; axscrollarea 1 for icon, list and gallery
      if mainArea then
        return mainArea:attributeValue("AXChildren")[1]
      end
    end

    local function focusMainArea(appObj)
      -- move focus to files area
      -- scroll area 1 = the common ancestor to all Finder views (list, columns, icons, etc...)
      -- assumption: the files area ui element is different for every view, but it is always to the first child
      getMainArea(appObj):setAttributeValue("AXFocused", true)
      for _ = 1, 3 do
        if getFinderSelection() == nil then
          eventtap.keyStroke({}, "down")
        else
          break
        end
      end
    end

    local function isSearchModeActive(appObj)
      if not appObj or not appObj:focusedWindow() or not appObj:focusedWindow():title() then
        return
      end
      if string.match(appObj:focusedWindow():title(), "^Searching “.+”$") then
        -- if search field is focused
        local axApp = ax.applicationElement(appObj)
        if axApp:attributeValue("AXFocusedUIElement"):attributeValue("AXSubrole") == "AXSearchField" then
          return true
        end
      end
    end

    local function moveFocusToFilesAreaIfInSearchMode(appObj, modal)
      if isSearchModeActive(appObj) then
        focusMainArea(appObj)
      else
        modal:exit()
        eventtap.keyStroke({}, "tab")
        modal:enter()
      end
    end

    local function openPackage()
      osascript.applescript([[
      tell application "Finder"
      set theSelection to selection
      set thePaths to {}
      repeat with i from 1 to count theSelection
        set theSelected to item i of theSelection
        try
        set theTarget to folder "Contents" of theSelected
        on error
        set theTarget to theSelected
      end try
      set end of thePaths to theTarget
    end repeat
      if (count of thePaths) is 1 then
        set target of Finder window 1 to (item 1 of thePaths)
        return
      end if
      if (count of thePaths) > 1 then
        open thePaths as alias list
      end if
    end tell]])
  end

  local function toggleColumns()
    local function selectColumnChooserCallback(choice)
      osascript.applescript([[
      tell application "System Events"
      tell process "Finder"
      click menu item "Show View Options" of menu 1 of menu bar item "View" of menu bar 1
      delay 2
      tell window 1
      tell group 1
      click checkbox "]] .. choice.text .. [["
    end tell
    click button 2
  end tell
end tell
end tell
]])
end
local columnChoices = {}
local columns = {
  "iCloud Status",
  "Date Modified",
  "Date Created",
  "Date Last Opened",
  "Date Added",
  "Size",
  "Kind",
  "Version",
  "Comments",
  "Tags",
}
for _, col in ipairs(columns) do
  table.insert(columnChoices, {["text"] = col})
end
timer.doAfter(0.1, function()
  GlobalChooser:start(selectColumnChooserCallback, columnChoices, {"text"})
end)
end

obj.modal = nil

--- browseInLaunchBar - shows files of the current folder in LaunchBar. Requires my [LaunchBar actions](https://github.com/roeybiran/launchbar-actions).
obj.actions = {
  browseInLaunchBar = {
    action = function()
      browseInLaunchBar()
    end,
    hotkey = {"alt", "f"}
  },
  --- newWindow - ensure a new window is opened rather than a tab. Relevant when the "Prefer tabs" is set to "Always" in the Dock preference pane.
  newWindow = {
    action = function()
      newWindow(obj.modal)
    end,
    hotkey = {"cmd", "n"}
  },
  --- moveFocusToFilesAreaIfInSearchMode - while in search view and the search field is focused, moves focus to the first result/file.
  moveFocusToFilesAreaIfInSearchMode = {
    action = function()
      moveFocusToFilesAreaIfInSearchMode(_appObj, obj.modal)
    end,
    hotkey = {{}, "tab"}
  },
  --- showOriginalFile - show the origin of an alias/symlink.
  showOriginalFile = {
    action = function()
      _appObj:selectMenuItem({"File", "Show Original"})
    end,
    hotkey = {{"shift", "cmd"}, "up"}
  },
  --- openInNewTab - opens the selected folder in a new tab.
  openInNewTab = {
    action = function()
      _appObj:selectMenuItem({"File", "Open in New Tab"})
    end,
    hotkey = {{"shift", "cmd"}, "down"}
  },
  --- openPackage - browses the inside of a package/bundle, rather than opens it.
  openPackage = {
    action = function()
      openPackage()
    end,
    hotkey = {"alt", "o"}
  },
  --- rightSizeColumnAllColumns - in columns view, right sizes all columns.
  rightSizeColumnAllColumns = {
    action = function()
      rightSizeColumn(_appObj, "all")
    end,
    hotkey = {{"alt", "shift"}, "r"}
  },
  --- rightSizeColumnThisColumn - in columns view, right sizes the active/selected column. In list view, right sizes the first column.
  rightSizeColumnThisColumn = {
    action = function()
      rightSizeColumn(_appObj, "this")
    end,
    hotkey = {"alt", "r"}},
  }

  function obj:start(appObj)
    _appObj = appObj
    obj.modal:enter()
    return self
  end

  function obj:stop()
    obj.modal:exit()
    return self
  end

  return obj
