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
local obj = {}

obj.__index = obj
obj.name = "ApplicationModalManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local _watcher = nil
local frontAppBundleID = nil
local windowFilter = nil
local appModals = {}

local function updateAppModal(appObj, bundleID)
  for _, module in ipairs(appModals) do
    if module.bundleID == bundleID then
      module:start(appObj)
    else
      module:stop()
    end
  end
end

local function mainCallback(_, event, appObj)
  local newBundleID = appObj:bundleID()
  if event == Application.watcher.activated or event == "FROM_WINDOW_WATCHER" then
    if newBundleID == frontAppBundleID then
      return
    end
    frontAppBundleID = newBundleID
    updateAppModal(appObj, newBundleID)
  end
end

local function windowFilterCallback(hsWindow, _, event)
  -- second arg is the app's name
  local appObj = hsWindow:application()
  if not appObj then
    return
  end
  local bundleID = appObj:bundleID()
  if event == "windowFocused" or event == "windowCreated" then
    if bundleID == frontAppBundleID then
      return
    end
    mainCallback(nil, "FROM_WINDOW_WATCHER", appObj)
  elseif event == "windowDestroyed" then
    mainCallback(nil, Application.watcher.activated, Application.frontmostApplication())
  end
end

--- AppWatcher.transientApps
---
--- Variable
---
--- A table containing apps you consider to be transient and want to be taken into account by the window filter. Elements should have the same structure as the `filters` parameter of hs.window.filter `setFilters` method.
obj.transientApps = {
  ["LaunchBar"] = {allowRoles = "AXSystemDialog"},
  ["1Password 7"] = {allowTitles = "1Password mini"},
  ["Spotlight"] = {allowRoles = "AXSystemDialog"},
  ["Paletro"] = {allowRoles = "AXSystemDialog"},
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true,
}

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
    Window.filter.windowCreated,
    Window.filter.windowDestroyed,
    Window.filter.windowFocused,
  }
  -- on reload, enter modal (if any) for the front app (saves an redundant cmd+tab)
  local frontApp = Application.frontmostApplication()
  if frontApp then
    mainCallback(nil, Application.watcher.activated, frontApp)
  end
  _watcher:start()
  windowFilter:setFilters(obj.transientApps)
  windowFilter:subscribe(allowedWindowFilterEvents, windowFilterCallback)
  return self
end

function obj:init()
  windowFilter = Window.filter.new(false)
  _watcher = Application.watcher.new(mainCallback)

  local app_hotkeys = dofile(Spoons.resourcePath("app_hotkeys.lua"))
  local iterFn, dirObj = FS.dir(Spoons.resourcePath("apps/"))
  if iterFn then
    for file in iterFn, dirObj do
      if string.sub(file, -3) == "lua" then
        local module = dofile(Spoons.resourcePath("apps/" .. file))
        local hotkeys_for_app = app_hotkeys[module.bundleID] or {}
        module:init()
        module:bindModalHotkeys(hotkeys_for_app)
        table.insert(appModals, module)
      end
    end
  end
  return self
end

return obj
