--- === AppearanceWatcher ===
---
--- Runs a callback when the macOS theme changes.

local obj = {}

obj.__index = obj
obj.name = "AppearanceWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local watcher
local callback

function obj:init()
	watcher =
		hs.distributednotifications.new(
		function(_)
			callback(hs.host.interfaceStyle() == 'Dark');
		end,
		"AppleInterfaceThemeChangedNotification",
		nil
	)
	return self
end

function obj:start(_callback)
	watcher:start()
	callback = _callback
	return self
end

return obj
