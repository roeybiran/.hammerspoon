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

-- load spoons
local iterFn, dirObj = hs.fs.dir("Spoons/")
if iterFn then
	for file in iterFn, dirObj do
		if string.sub(file, -5) == "spoon" then
			local spoonName = string.sub(file, 1, -7)
			hs.loadSpoon(spoonName)
		end
	end
end

-- start spoons (order matters!)
spoon.ConfigWatcher:start()
spoon.DownloadsWatcher:start(require "downloadswatcher_rules")
spoon.StatusBar:start()
spoon.KeyboardLayoutSwitcher:start({}, "ABC")
spoon.WindowManager:bindHotKeys(config.windowManagerShortcuts or {}):start()
spoon.NotificationCenter:bindHotKeys(config.notificationCenterShortcuts or {})
spoon.AppearanceWatcher:start(config.appearanceWatcherCallback)

hs.wifi.watcher.new(config.wifiWatcherCallback):start()

function StartScreenCleaner()
	local eventsToIgnore = {
		hs.eventtap.event.types.leftMouseDown,
		hs.eventtap.event.types.leftMouseUp,
		hs.eventtap.event.types.mouseMoved
	}

	local eventTap = hs.eventtap.new({ "all", eventsToIgnore }, function()
		return true
	end
	)

	hs.webview.new(hs.screen.primaryScreen():fullFrame())
		:level(hs.drawing.windowLevels.overlay)
		:html([[
			<!DOCTYPE html>
			<html>
			<head>
				<meta charset="UTF-8">
				<style>
					* {
						margin: 0;
						padding: 0;
						box-sizing: border-box;
					}

					body {
						background: black;
						width: 100vw;
						height: 100vh;
						display: flex;
						justify-content: center;
						align-items: center;
					}

					a {
						color: white;
					}
				</style>
			</head>
			<body>
				<a href="foo:bar">Exit Screen Cleaner</a>
			</body>
			</html>
		]])
		:policyCallback(function(_, webview, table)
			local url = table.request.URL.url
			if url == "about:blank" then
				return true
			else
				webview:delete()
				eventTap:stop()
				return false
			end
		end)
		:show()

	eventTap:start()
end
