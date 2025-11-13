local private = require("private.private")

return {
	terminal = "com.github.wez.wezterm",
	appearanceWatcherCallback = function(isDarkMode) end,
	wifiWatcherCallback = function()
		hs.timer.doAfter(
			2,
			function()
				local settingKey = "RBMuteSoundWhenJoiningUnknownNetworks"

				local shouldMute = hs.settings.get(settingKey)
				if not shouldMute then return end

				local currentWifi = hs.wifi.currentNetwork()
				if not currentWifi then return end

				local isKnownNetwork = hs.fnutils.contains(private.knownNetworks, currentWifi)

				hs.audiodevice.defaultOutputDevice():setOutputMuted(not isKnownNetwork)
			end
		)
	end
}
