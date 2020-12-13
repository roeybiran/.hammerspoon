local hyper = {"shift", "cmd", "alt", "ctrl"}

local hotkeys = {
  ["com.apple.finder"] = {
    browseInLaunchBar = {"alt", "f"},
    -- focusMainArea = {"alt", "2"},
    newWindow = {"cmd", "n"},
    undoCloseTab = {{"shift", "cmd"}, "t"},
    moveFocusToFilesAreaIfInSearchMode = {{}, "tab"},
    showOriginalFile = {{"shift", "cmd"}, "up"},
    openInNewTab = {{"shift", "cmd"}, "down"},
    openPackage = {"alt", "o"},
    rightSizeColumnAllColumns = {{"alt", "shift"}, "r"},
    rightSizeColumnThisColumn = {"alt", "r"}
  },
  ["com.apple.Safari"] = {
    moveTabLeft = {"ctrl", ","},
    moveTabRight = {"ctrl", "."},
    newWindow = {"cmd", "n"},
    goToNextPage = {"ctrl", "n"},
    goToPreviousPage = {"ctrl", "p"},
    moveFocusToMainAreaAndChangeToABCAfterOpeningLocation = {{}, "return"},
    changeToABCAfterFocusingAddressBar = {"cmd", "l"},
    -- focusSidebar = {"alt", "1"},
    -- focusMainArea = {"alt", "2"},
    newBookmarksFolder = {{"cmd", "shift"}, "n"},
    rightSizeBookmarksOrHistoryColumn = {"alt", "r"},
    firstSearchResult = {{}, "tab"}
  },
  ["at.obdev.LaunchBar.ActionEditor"] = {pane1 = {"alt", "1"}, pane2 = {"alt", "2"}},
  ["com.apple.Notes"] = {
    pane1 = {"alt", "1"},
    pane2 = {"alt", "2"},
    pane3 = {"alt", "3"},
    searchNotesWithLaunchBar = {{"shift", "cmd"}, "o"}
  },
  ["com.apple.ActivityMonitor"] = {
    radioButton1 = {"cmd", "1"},
    radioButton2 = {"cmd", "2"},
    radioButton3 = {"cmd", "3"},
    radioButton4 = {"cmd", "4"},
    radioButton5 = {"cmd", "5"},
    quitProcess = {"cmd", "delete"}
  },
  ["com.agilebits.onepassword7"] = {pane1 = {"alt", "1"}, pane2 = {"alt", "2"}},
  ["com.adobe.illustrator"] = {nextTab = {"ctrl", "tab"}, previousTab = {{"ctrl", "shift"}, "tab"}},
  ["Adobe InDesign"] = {nextTab = {"ctrl", "tab"}, previousTab = {{"ctrl", "shift"}, "tab"}},
  ["com.apple.AppStore"] = {goBack = {"cmd", "["}},
  ["com.kapeli.dashdoc"] = {
    -- pane1 = {},
    -- pane2 = {},
    clickOnHistoryMenuItem = {"cmd", "y"},
    toggleBookmarks = {{"cmd", "alt"}, "b"}
  },
  ["org.hammerspoon.Hammerspoon"] = {clearConsole = {"cmd", "k"}, reload = {"cmd", "r"}},
  ["com.apple.mail"] = {selectNextMessage = {"ctrl", "tab"}, selectPrevMessage = {{"ctrl", "shift"}, "tab"}},
  ["com.apple.iChat"] = {getMessageLinks = {"alt", "o"}},

  -- globals
  keyboardLayoutManager = {toggleInputSource = {{}, 10}},
  globals = {focusMenuBar = {{"cmd", "shift"}, "1"}, rightClick = {hyper, "o"}, focusDock = {{"cmd", "alt"}, "d"}},
  windowManager = {
    pushLeft = {hyper, "left"},
    pushRight = {hyper, "right"},
    pushUp = {hyper, "up"},
    pushDown = {hyper, "down"},
    maximize = {hyper, "return"},
    center = {hyper, "c"}
  },
  notificationCenter = {
    firstButton = {hyper, "1"},
    secondButton = {hyper, "2"},
    thirdButton = {hyper, "3"},
    toggle = {hyper, "n"}
  }
}

return hotkeys
