local FS = require("hs.fs")
local window = require("hs.window")
local ipc = require("hs.ipc")
local application = require("hs.application")
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

application.enableSpotlightForNameSearches(true)
ipc.cliUninstall()
ipc.cliInstall()
window.animationDuration = 0

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
  defaultHideInterval = 1800 -- 30 minutes
})

spoon.AppWatcher:start()
spoon.AppearanceWatcher:start()
spoon.ConfigWatcher:start()
spoon.DownloadsWatcher:start()
spoon.WifiWatcher:start()
spoon.StatusBar:start()

-- HOTKEYS ---
local hotkeys = require("hotkeys")
-- global
spoon.KeyboardLayoutManager:bindHotKeys(hotkeys.keyboardLayoutManager)
spoon.Globals:bindHotKeys(hotkeys.globals)
spoon.WindowManager:bindHotKeys(hotkeys.windowManager)
spoon.NotificationCenter:bindHotKeys(hotkeys.notificationCenter)
-- app-specific
for _, _spoon in pairs(spoon) do
  if _spoon.bindModalHotkeys and hotkeys[_spoon.bundleID] then
    _spoon:bindModalHotkeys(hotkeys[_spoon.bundleID])
  end
end
