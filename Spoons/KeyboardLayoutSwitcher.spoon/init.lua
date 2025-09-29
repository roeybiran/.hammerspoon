--- === KeyboardLayoutSwitcher ===
---
--- A module that handles automatic keyboard layout switching under varying contexts.
--- Saves the last used layout in a given app, and switches back to that layout when that app activates.

local spoon = spoon

local obj = {}
local watcher
obj.__index = obj
obj.name = "KeyboardLayoutSwitcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local avoidSwitchingInputSourceOnActivation = {}
local _defaultLayout
local defaultsKey = "RBAppsLastActiveKeyboardLayouts"

local previousApp

local function appWatcherCallback(appName, event, app)
	if event ~= hs.application.watcher.activated then
		return
	end

	local settingsTable = hs.settings.get(defaultsKey) or {}
	local currentApp = app:bundleID()
	-- capture the layout before changing, it's essentially the last active layout for the previous app
	local currentLayout = hs.keycodes.currentLayout()

	if previousApp then
		settingsTable[previousApp] = {
			-- TODO: reset back to default layout based on timestamp?
			["LastActiveKeyboardLayoutTimestamp"] = os.time(),
			["LastActiveKeyboardLayout"] = currentLayout
		}
		hs.settings.set(defaultsKey, settingsTable)
	end

	previousApp = currentApp

	local newLayout = (settingsTable[currentApp] or {})["LastActiveKeyboardLayout"] or _defaultLayout

	if not hs.fnutils.contains(avoidSwitchingInputSourceOnActivation, currentApp) then
		hs.keycodes.setLayout(newLayout)
	end
end

--- KeyboardLayoutSwitcher:start(ignored)
--- Method
--- Starts the module.
---
--- Parameters:
---  * `ignored` - A table of bundle IDs of apps for which layout switching should be avoided.
---  * `defaultLayout` - The default layout to use if an app doesn't have a previously associated layout.
---
--- Returns:
---  * the module object.
function obj:start(ignored, defaultLayout)
	_defaultLayout = defaultLayout
	avoidSwitchingInputSourceOnActivation = ignored or {}
	watcher = hs.application.watcher.new(appWatcherCallback)
	watcher:start()
	return self
end

return obj
