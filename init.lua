local config = require("config")

-- HAMMERSPOON SETTINGS, VARIABLES
hs.allowAppleScript(true)
hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
hs.application.enableSpotlightForNameSearches(true)
hs.menuIcon(false)
hs.dockIcon(false)
hs.hotkey.setLogLevel("error")
hs.keycodes.log.setLogLevel("error")
hs.logger.defaultLogLevel = "error"
hs.ipc.cliUninstall()
hs.ipc.cliInstall()
hs.window.animationDuration = 0

-- SPOONS

-- load
local iterFn, dirObj = hs.fs.dir("Spoons/")
if iterFn then
	for file in iterFn, dirObj do
		if string.sub(file, -5) == "spoon" then
			local spoonName = string.sub(file, 1, -7)
			hs.loadSpoon(spoonName)
		end
	end
end

local layoutSwitcherIgnored = {"at.obdev.LaunchBar", "com.contextsformac.Contexts"}

-- start (ORDER MATTERS!)
spoon.AppQuitter:start(config.appQuitter)
spoon.AppShortcuts:start(config.transientApps)
spoon.ConfigWatcher:start()
spoon.DownloadsWatcher:start(require "downloadswatcher_rules")
spoon.StatusBar:start()
-- spoon.KeyboardLayoutManager:start(layoutSwitcherIgnored, "ABC")
spoon.GlobalShortcuts:bindHotKeys(config.globalShortcuts)
spoon.WindowManager:bindHotKeys(config.windowManagerShortcuts):start()
spoon.NotificationCenter:bindHotKeys(config.notificationCenterShortcuts)
spoon.AppearanceWatcher:start(config.appearanceWatcherCallback)

wifiWatcher = hs.wifi.watcher.new(config.wifiWatcherCallback):start()
