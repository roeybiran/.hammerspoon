--- === AppearanceWatcher ===
---
--- Perform actions when the system's theme changes. Actions can be configured by editing the shell script inside the Spoon's directory.
local task = require("hs.task")
local settings = require("hs.settings")
local PathWatcher = require("hs.pathwatcher")
local Host = require("hs.host")

local obj = {}

obj.__index = obj
obj.name = "AppearanceWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local watcher
local appearanceWatcherActiveKey = "RBAppearanceWatcherIsActive"
local cachedInterfaceStyleKey = "RBAppearanceWatcherCachedInterfaceStyle"
local appearancePlist = os.getenv("HOME") .. "/Library/Preferences/.GlobalPreferences.plist"

local function appearanceChangedCallback(isDarkMode)
	-- launchbar theme
	local launchbarTheme = (isDarkMode and "at.obdev.LaunchBar.theme.Dark") or "at.obdev.LaunchBar.theme.Default"
	os.execute(string.format('/usr/bin/defaults write at.obdev.LaunchBar Theme -string "%s"', launchbarTheme))

	-- Hammerspoon's console
	hs.console.darkMode(isDarkMode)
end

function obj:init()
	if settings.get(appearanceWatcherActiveKey) == nil then
		settings.set(appearanceWatcherActiveKey, true)
	end
	if settings.get(appearanceWatcherActiveKey) then
		obj:start()
	end
	return self
end

--- AppearanceWatcher:stop()
--- Method
--- Stops this module.
---
--- Returns:
---  * the module object.
function obj:stop()
	watcher:stop()
	watcher = nil
	return self
end

--- AppearanceWatcher:start()
--- Method
--- starts this module.
---
--- Returns:
---  * the module object.
function obj:start()
	watcher =
		PathWatcher.new(
		appearancePlist,
		function()
			local currentSystemStyle = Host.interfaceStyle() or "Light"
			local cachedStyle = settings.get(cachedInterfaceStyleKey)
			if currentSystemStyle ~= cachedStyle then
				print(
					string.format("AppearanceWatcher: detected a system style change, from %s to %s", cachedStyle, currentSystemStyle)
				)
				settings.set(cachedInterfaceStyleKey, currentSystemStyle)
				appearanceChangedCallback(currentSystemStyle == "Dark")
			end
		end
	):start()
	return self
end

--- AppearanceWatcher:toggle()
--- Method
--- Toggles this module.
---
--- Returns:
---  * the module object.
function obj:toggle()
	if obj:isActive() then
		settings.set(appearanceWatcherActiveKey, false)
		obj:stop()
	else
		settings.set(appearanceWatcherActiveKey, true)
		obj:start()
	end
	return self
end

--- AppearanceWatcher:isActive()
--- Method
--- Determines whether module is active.
---
--- Returns:
---  * A boolean, true if the module's watcher is active, otherwise false
function obj.isActive()
	return watcher ~= nil
end

return obj
