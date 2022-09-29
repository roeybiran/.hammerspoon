local FS = require("hs.fs")
local window = require("hs.window")
local ipc = require("hs.ipc")
local hs = hs

local transientApps = {
	["LaunchBar"] = {allowRoles = "AXSystemDialog"},
	["1Password 7"] = {allowTitles = "1Password mini"},
	["Spotlight"] = {allowRoles = "AXSystemDialog"},
	["Paletro"] = {allowRoles = "AXSystemDialog"},
	["Contexts"] = false,
	["Emoji & Symbols"] = true
}

local layoutSwitcherIgnored = {"at.obdev.LaunchBar", "com.contextsformac.Contexts"}

local appQuitterConfig = {
	launchdRunInterval = 600, --- 10 minutes
	rules = require("appquitter_rules"),
	defaultQuitInterval = 14400, -- 4 hours
	defaultHideInterval = 1800 -- 30 minutes
}

local hyper = {"shift", "cmd", "alt", "ctrl"}

local globalShortcuts = {
	globals = {
		rightClick = {hyper, "o"},
		focusDock = {
			{"cmd", "alt"},
			"d"
		}
	},
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
spoon.AppQuitter:start(appQuitterConfig)
spoon.AppShortcuts:start(transientApps)
spoon.ConfigWatcher:start()
spoon.DownloadsWatcher:start(require "downloadswatcher_rules")
spoon.WifiWatcher:start(require "wifiwatcher_rules")
spoon.StatusBar:start()
spoon.KeyboardLayoutManager:start(layoutSwitcherIgnored, "ABC")
spoon.GlobalShortcuts:bindHotKeys(globalShortcuts.globals)
spoon.WindowManager:bindHotKeys(globalShortcuts.windowManager):start()
spoon.NotificationCenter:bindHotKeys(globalShortcuts.notificationCenter)

hs.hotkey.bind(
	hyper,
	"t",
	function()
		hs.osascript.applescript(
			[[
			if app "iTerm" is not frontmost then
				tell app "iTerm" to activate
			else
				tell app "System Events" to set visible of application process "iTerm2" to false
			end if
			]]
		)
	end,
	nil,
	nil
)
