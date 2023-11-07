local hyper = { "shift", "cmd", "alt", "ctrl" }

return {
	transientApps = {
		["LaunchBar"] = { allowRoles = "AXSystemDialog" },
		["1Password 7"] = { allowTitles = "1Password mini" },
		["Spotlight"] = { allowRoles = "AXSystemDialog" },
		["Paletro"] = { allowRoles = "AXSystemDialog" },
		["Contexts"] = false,
		["Emoji & Symbols"] = true
	},
	globalShortcuts = {
		rightClick = { hyper, "o" },
		openTerminal = { hyper, "t" },
		focusDock = {
			{ "cmd", "alt" },
			"d"
		}
	},
	notificationCenterShortcuts = {
		firstButton = { hyper, "1" },
		secondButton = { hyper, "2" },
		thirdButton = { hyper, "3" },
		toggle = { hyper, "n" }
	},
	windowManagerShortcuts = {
		pushLeft = { hyper, "left" },
		pushRight = { hyper, "right" },
		pushUp = { hyper, "up" },
		pushDown = { hyper, "down" },
		maximize = { hyper, "return" },
		center = { hyper, "c" }
	},
	appQuitter = {
		launchdRunInterval = 600, --- 10 minutes
		rules = {
			"abnerworks.Typora",
			"app.soulver.mac",
			"com.adobe.AfterEffects",
			"com.adobe.illustrator",
			"com.adobe.InDesign",
			"com.adobe.Photoshop",
			"com.apple.ActivityMonitor",
			"com.apple.AddressBook",
			"com.apple.airport.airportutility",
			"com.apple.AppStore",
			"com.apple.audio.AudioMIDISetup",
			"com.apple.Automator",
			"com.apple.backup.launcher",
			"com.apple.BluetoothFileExchange",
			"com.apple.bootcampassistant",
			"com.apple.calculator",
			"com.apple.Chess",
			"com.apple.ColorSyncUtility",
			"com.apple.Console",
			"com.apple.Dictionary",
			"com.apple.DigitalColorMeter",
			"com.apple.DiskUtility",
			"com.apple.FaceTime",
			"com.apple.findmy",
			"com.apple.FontBook",
			"com.apple.grapher",
			"com.apple.Home",
			"com.apple.iBooksX",
			"com.apple.iCal",
			"com.apple.iChat",
			"com.apple.Image_Capture",
			"com.apple.iWork.Keynote",
			"com.apple.iWork.Numbers",
			"com.apple.iWork.Pages",
			"com.apple.keychainaccess",
			"com.apple.Maps",
			"com.apple.MigrateAssistant",
			"com.apple.Music",
			"com.apple.Notes",
			"com.apple.PhotoBooth",
			"com.apple.Photos",
			"com.apple.podcasts",
			"com.apple.QuickTimePlayerX",
			"com.apple.reminders",
			"com.apple.screenshot.launcher",
			"com.apple.ScriptEditor2",
			"com.apple.SFSymbols",
			"com.apple.Stickies",
			"com.apple.stocks",
			"com.apple.systempreferences",
			"com.apple.SystemProfiler",
			"com.apple.Terminal",
			"com.apple.TextEdit",
			"com.apple.TV",
			"com.apple.VoiceMemos",
			"com.apple.VoiceOverUtility",
			"com.bjango.istatmenus",
			"com.bohemiancoding.sketch3",
			"com.colliderli.iina",
			"com.coteditor.CotEditor",
			"com.cryptic-apps.hopper-web-4",
			"com.electron.realtimeboard",
			"com.figma.Desktop",
			"com.giorgiocalderolla.Wipr-Mac",
			"com.groosoft.CommentHere",
			"com.macitbetter.betterzip",
			"com.pfiddlesoft.uibrowser",
			"com.postmanlabs.mac",
			"com.roeybiran.Milonchik",
			"com.samuelmeuli.Glance",
			"com.savantav.truecontrol",
			"com.ScooterSoftware.BeyondCompare",
			"com.sidetree.Translate",
			"com.sindresorhus.Color-Picker",
			"com.wolfrosch.Gapplin",
			"de.just-creative.inddPreview",
			"developer.apple.wwdc-Release",
			"io.dictionaries.Dictionaries",
			"me.spaceinbox.Select-Like-A-Boss-For-Safari",
			"net.bluem.pashua",
			"net.freemacsoft.AppCleaner",
			"net.shinyfrog.bear",
			"net.shinyfrog.panda",
			"net.sourceforge.sqlitebrowser",
			"net.televator.Vimari",
			"pl.maketheweb.pixelsnap2",
			"us.zoom.xos",
			["at.obdev.LaunchBar.ActionEditor"] = { quit = 0.5 },
			["com.apple.dt.Xcode"] = { quit = 8, hide = 1 },
			["com.apple.iphonesimulator"] = { quit = 1 },
			["com.brave.Browser"] = { quit = 8 },
			["com.kapeli.dashdoc"] = { quit = 24, hide = 1 },
			["com.latenightsw.ScriptDebugger7"] = { quit = 1 },
			["com.microsoft.VSCode"] = { quit = 8, hide = 1 },
			["com.toggl.toggldesktop.TogglDesktop"] = { quit = 8, hide = 0.1 },
			"com.spotify.client"
		},
		defaultQuitInterval = 14400, -- 4 hours
		defaultHideInterval = 1800 -- 30 minutes
	},
	appearanceWatcherCallback = function(isDarkMode)
		-- Hammerspoon's console
		hs.console.darkMode(isDarkMode)

		-- iTerm
		local theme = isDarkMode and "Dark" or "Light"
		hs.osascript.applescript(
			string.format(
				[[
            tell application id "com.googlecode.iterm2"
            repeat with i from 0 to count windows
                set theWindow to item i of windows
                repeat with j from 0 to count tabs of theWindow
                    set theTab to item j of tabs of theWindow
                    repeat with k from 0 to count sessions of theTab
                        set theSession to item k of sessions of theTab
                        tell theSession
                            set color preset to "Solarized %s"
                        end tell
                    end repeat
                end repeat
            end repeat
        end tell
        ]],
				theme
			)
		)
	end,
	wifiWatcherCallback = function()
		hs.timer.doAfter(
			2,
			function()
				local settingKey = "RBMuteSoundWhenJoiningUnknownNetworks"
				local shouldMute = hs.settings.get(settingKey)
				if not shouldMute then return end
				local currentWifi = hs.wifi.currentNetwork()
				if not currentWifi then return end
				local knownNetworks = {
					"Biran",
					"Biran2",
					"BiranTLV",
					"roey",
					"Anchor1",
					"Anchor_new",
					"Anchor_Secure",
					"Studio Now"
				}

				local isKnownNetwork = hs.fnutils.some(
					knownNetworks,
					function(knownNetwork)
						return string.find(currentWifi, knownNetwork)
					end)

				hs.audiodevice.defaultOutputDevice():setOutputMuted(not isKnownNetwork)
			end
		)
	end
}
