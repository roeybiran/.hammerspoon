--- === ApplicationModalManager ===
---
--- Manages the activation and deactivation of the app-specific environments (hotkeys, event taps etc.) when an app goes in and out of focus, respectively.
--- Based on an `hs.application.watcher` instance, bolstered by `hs.window.filter` to catch and react on activation of "transient" apps, such as Spotlight.
--- To add a new modal for a given app, you must do the following:
---
local FS = require("hs.fs")
local Application = require("hs.application")
local Window = require("hs.window")
local Spoons = require("hs.spoons")
local Hotkey = require("hs.hotkey")

local appScriptsDir = Spoons.resourcePath("apps/")

local obj = {}
local _watcher = nil
local frontAppBundleID = nil
local windowFilter = nil
local appModals = {}

obj.__index = obj
obj.name = "ApplicationModalManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.currentBundleID = nil
obj.currentAppObj = nil

--- AppWatcher.transientApps
---
--- Variable
---
--- A table containing apps you consider to be transient and want to be taken into account by the window filter.
--- Elements should have the same structure as the `filters` parameter of hs.window.filter `setFilters` method.
obj.transientApps = {
  ["LaunchBar"] = {allowRoles = "AXSystemDialog"},
  ["1Password 7"] = {allowTitles = "1Password mini"},
  ["Spotlight"] = {allowRoles = "AXSystemDialog"},
  ["Paletro"] = {allowRoles = "AXSystemDialog"},
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true
}

local function enterAppEnvironment(appObj, bundleID)
    for key, value in pairs(appModals) do
        if key == bundleID then
            value:start(appObj)
        else
            value:stop()
        end
    end
end

local function appWatcherCallback(_, event, appObj)
    local newBundleID = appObj:bundleID()
    if event == Application.watcher.activated or event == "FROM_WINDOW_WATCHER" then
        if newBundleID == frontAppBundleID then return end
        frontAppBundleID = newBundleID
        enterAppEnvironment(appObj, newBundleID)
        obj.currentBundleID = newBundleID
    end
end

local function windowFilterCallback(hsWindow, appName, event)
    local appObj = hsWindow:application()
    if not appObj then return end
    local bundleID = appObj:bundleID()
    if event == "windowFocused" or event == "windowCreated" then
        if bundleID == frontAppBundleID then
          return
        end
        appWatcherCallback(nil, "FROM_WINDOW_WATCHER", appObj)
    elseif event == "windowDestroyed" then
        appWatcherCallback(nil, Application.watcher.activated, Application.frontmostApplication())
    end
end

--- AppWatcher.stop()
---
--- Method
---
--- Stops the module.
---
function obj:stop()
    windowFilter:unsubscribe()
    _watcher:stop()
    return self
end

--- AppWatcher:start()
---
--- Method
---
--- Starts the module.
---
function obj:start()
    local allowedWindowFilterEvents = {
        Window.filter.windowCreated, Window.filter.windowDestroyed,
        Window.filter.windowFocused
    }
    -- on reload, enter modal (if any) for the front app (saves an redundant cmd+tab)
    local frontApp = Application.frontmostApplication()
    if frontApp then
        appWatcherCallback(nil, Application.watcher.activated, frontApp)
    end
    _watcher:start()
    windowFilter:setFilters(obj.transientApps)
    windowFilter:subscribe(allowedWindowFilterEvents, windowFilterCallback)
    return self
end

function obj:init()
    windowFilter = Window.filter.new(false)
    _watcher = Application.watcher.new(appWatcherCallback)
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
