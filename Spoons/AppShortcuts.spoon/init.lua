--- === ApplicationModalManager ===
---
--- Manages the activation and deactivation of the app-specific environments (hotkeys, event taps etc.) when an app goes in and out of focus, respectively.
local FS = require("hs.fs")
local Spoons = require("hs.spoons")
local Hotkey = require("hs.hotkey")

local Watcher = hs.loadSpoon("CustomAppWatcher")

local appScriptsDir = Spoons.resourcePath("apps/")
local obj = {}
local appModals = {}

obj.__index = obj
obj.name = "ApplicationModalManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function enterAppEnvironment(appObj, bundleID)
    for key, value in pairs(appModals) do
        if key == bundleID then
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
--- Parameters:
---  * transientApps - A table, default empty, containing apps you consider to be transient and want to be taken into account by the window filter. Elements should have the same structure as the `filters` parameter of `hs.window.filter`’s `setFilters` method.
---
--- Returns:
---  * self, for method chaining.
function obj:start(transientApps)
		Watcher:start(transientApps, function (bundleId, appObj, isWinFilterEvent)
			print(bundleId, appObj, isWinFilterEvent)
			enterAppEnvironment(appObj, bundleId)
		end)
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
