local FS = require("hs.fs")
local window = require("hs.window")
local ipc = require("hs.ipc")
local hs = hs

local config = require('config')

local layoutSwitcherIgnored = {"at.obdev.LaunchBar", "com.contextsformac.Contexts"}

-- HAMMERSPOON SETTINGS, VARIABLES
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

-- SPOONS

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

-- start (ORDER MATTERS!)
spoon.AppQuitter:start(config.appQuitter)
spoon.AppShortcuts:start(config.transientApps)
spoon.ConfigWatcher:start()
spoon.DownloadsWatcher:start(require "downloadswatcher_rules")
spoon.WifiWatcher:start(require "wifiwatcher_rules")
spoon.URLHandler:start()
spoon.StatusBar:start()
spoon.KeyboardLayoutManager:start(layoutSwitcherIgnored, "ABC")
spoon.GlobalShortcuts:bindHotKeys(config.globalShortcuts)
spoon.WindowManager:bindHotKeys(config.windowManagerShortcuts):start()
spoon.NotificationCenter:bindHotKeys(config.notificationCenterShortcuts)
spoon.AppearanceWatcher:start(config.appearanceWatcherCallback)

local hyper = {"shift", "cmd", "alt", "ctrl"}
hs.hotkey.bind(
	hyper,
	"t",
	function()
		local termBundleID = "com.googlecode.iterm2"
		local app = hs.application.get(termBundleID)
		if app:isFrontmost() then
			app:hide()
		else
			hs.application.launchOrFocusByBundleID(termBundleID)
		end
	end,
	nil,
	nil
)
