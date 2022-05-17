--- === ApplicationModalManager ===
---
--- Manages the activation and deactivation of the app-specific environments (hotkeys, event taps etc.) when an app goes in and out of focus, respectively.
local FS = require("hs.fs")
local Spoons = require("hs.spoons")
local Hotkey = require("hs.hotkey")
local Application = require("hs.application")

local appScriptsDir = Spoons.resourcePath("apps/")
local obj = {}
local appModals = {}
local watcher

obj.__index = obj
obj.name = "ApplicationModalManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function enterAppEnvironment(appName, event, appObj)
	if event ~= Application.watcher.activated then
		return
	end
	for key, value in pairs(appModals) do
		if key == appObj:bundleID() then
			value:start(appObj)
		else
			value:stop()
		end
	end
end

--- AppWatcher:start()
--- Method
--- Starts the module.
---
--- Returns:
---  * self, for method chaining.
function obj:start(transientApps)
	watcher = Application.watcher.new(enterAppEnvironment)
	watcher:start()
	-- on reload, enter modal (if any) for the front app (saves a redundant cmd+tab)
	local frontApp = Application.frontmostApplication()
	if frontApp then
		enterAppEnvironment(nil, Application.watcher.activated, frontApp)
	end
	return self
end

function obj:init()
	local iterFn, dirObj = FS.dir(appScriptsDir)
	if iterFn then
		for file in iterFn, dirObj do
			if string.sub(file, -3) == "lua" then
				local basenameAndBundleID = string.sub(file, 1, -5)
				local script = dofile(appScriptsDir .. file)
				script.modal = Hotkey.modal.new()
				for _, value in pairs(script.actions) do
					local hotkey = value.hotkey
					if hotkey then
						local mods, key = table.unpack(hotkey)
						script.modal:bind(mods, key, value.action)
					end
				end
				appModals[basenameAndBundleID] = script
			end
		end
	end
	return self
end

return obj
