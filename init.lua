local FS = require("hs.fs")
local window = require("hs.window")
local ipc = require("hs.ipc")
local hs = hs

----------------------------------
-- HAMMERSPOON SETTINGS, VARIABLES
----------------------------------
hs.allowAppleScript(true)
hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
hs.menuIcon(false)
hs.dockIcon(false)
hs.hotkey.setLogLevel("error")
hs.keycodes.log.setLogLevel("error")
hs.logger.defaultLogLevel = "error"
ipc.cliUninstall()
ipc.cliInstall()
window.animationDuration = 0

-- -- alternatively, call .nextWindow() or .previousWindow() directly (same as hs.window.switcher.new():next())
-- hs.hotkey.bind('alt','tab','Next window',hs.window.switcher.nextWindow)
-- -- you can also bind to `repeatFn` for faster traversing
-- hs.hotkey.bind('alt-shift','tab','Prev window',hs.window.switcher.previousWindow,nil,hs.window.switcher.previousWindow)
-- hs.window.switcher.ui.textColor = {0.9,0.9,0.9}

-- hs.window.switcher.ui.fontName = 'Lucida Grande'
-- hs.window.switcher.ui.textSize = 16
-- hs.window.switcher.ui.highlightColor = {0.8,0.5,0,0.8}
-- hs.window.switcher.ui.backgroundColor = {0.3,0.3,0.3,1}
-- hs.window.switcher.ui.onlyActiveApplication = false
-- hs.window.switcher.ui.showTitles = true
-- hs.window.switcher.ui.titleBackgroundColor = {0,0,0}
-- hs.window.switcher.ui.showThumbnails = false
-- hs.window.switcher.ui.thumbnailSize = 128
-- hs.window.switcher.ui.showSelectedThumbnail = true
-- hs.window.switcher.ui.selectedThumbnailSize = 384
-- hs.window.switcher.ui.showSelectedTitle = true

---------
-- SPOONS
---------

-- load
local iterFn, dirObj = FS.dir("Spoons/")
if iterFn then
  for file in iterFn, dirObj do
    if string.sub(file, -5) == "spoon" then
      local spoonName = string.sub(file, 1, -7)
      hs.loadSpoon(spoonName)
    end
  end
end

local spoon = spoon

-- start (ORDER MATTERS!)
spoon.AppQuitter:start({
  launchdRunInterval = 600, --- 10 minutes
  rules = require("appquitter_rules"),
  defaultQuitInterval = 14400, -- 4 hours
  defaultHideInterval = 1800, -- 30 minutes
})
spoon.AppShortcuts:start()
spoon.ConfigWatcher:start()
spoon.DownloadsWatcher:start()
spoon.WifiWatcher:start()
spoon.StatusBar:start()

-- HOTKEYS ---
local hyper = {"shift", "cmd", "alt", "ctrl"}
local globalShortcuts = {
  keyboardLayoutManager = {
    toggleInputSource = { {}, 10 }
  },
  globals = {
    focusMenuBar = {
      {"cmd", "shift"}, "1"
    },
    rightClick = {hyper, "o"},
    focusDock = {
      {"cmd", "alt"}, "d"}
    },
  windowManager = {
    pushLeft = {hyper, "left"},
    pushRight = {hyper, "right"},
    pushUp = {hyper, "up"},
    pushDown = {hyper, "down"},
    maximize = {hyper, "return"},
    center = {hyper, "c"},
  },
  notificationCenter = {
    firstButton = {hyper, "1"},
    secondButton = {hyper, "2"},
    thirdButton = {hyper, "3"},
    toggle = {hyper, "n"},
  },
}

-- global
spoon.KeyboardLayoutManager:bindHotKeys(globalShortcuts.keyboardLayoutManager):start()
spoon.GlobalShortcuts:bindHotKeys(globalShortcuts.globals)
spoon.WindowManager:bindHotKeys(globalShortcuts.windowManager)
spoon.NotificationCenter:bindHotKeys(globalShortcuts.notificationCenter)
