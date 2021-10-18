--- === KeyboardLayoutManager ===
---
--- A module that handles automatic keyboard layout switching under varying contexts.
--- Features:
--- * Saves the last used layout in a given app, and switches back to that layout when that app activates.
--- * Switches by default to "ABC" if there's no saved setting for a given app.
--- * Default switching behavior can be overridden for specific apps.
--- * For Safari, the switching behavior is tweaked so layout is saved and cycled on a per-tab basis. Needs _Safari.spoon.
local Keycodes = require("hs.keycodes")
local Settings = require("hs.settings")
local Spoons = require("hs.spoons")
local FNUtils = require("hs.fnutils")
local Window = require("hs.window")
local Application  = require("hs.application")
local DistributedNotifications = require("hs.distributednotifications")

local spoon = spoon

local obj = {}
local watcher
obj.__index = obj
obj.name = "KeyboardLayoutManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local avoidSwitchingInputSourceOnActivation = {}
local defaultsKey = "RBAppsLastActiveKeyboardLayouts"

-- called when the key to toggle the layout is pressed
local function setInputSourceOnKeyDown()
    local bundleID = Window.frontmostWindow():application():bundleID()

    local newLayout = "ABC"
    if Keycodes.currentLayout() == "ABC" then
        newLayout = "Hebrew"
    end

    Keycodes.setLayout(newLayout)
    DistributedNotifications.post("InputSourceDidChange")

    local settingsTable = Settings.get(defaultsKey) or {}
    settingsTable[bundleID] = {
      ["LastActiveKeyboardLayoutTimestamp"] = os.time(),
      ["LastActiveKeyboardLayout"] = newLayout,
    }

    Settings.set(defaultsKey, settingsTable)
end

local function setInputSourceOnAppActivation(appName, event, app)
    if event ~= Application.watcher.activated then return end;

    local bundleID = app:bundleID()
    if FNUtils.contains(avoidSwitchingInputSourceOnActivation, bundleID) then
        return
    end

    -- default to abc if no saved setting
    local newLayout = "ABC"

    local settingsTable = Settings.get(defaultsKey) or {}
    local oldSetting = settingsTable[bundleID]
    if oldSetting then
        -- TODO: reset back to abc based on timestamp?
        newLayout = oldSetting["LastActiveKeyboardLayout"]
    end
    Keycodes.setLayout(newLayout)
end

--- KeyboardLayoutManager:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for this module
--- Parameters:
---  * `mapping` - A table containing hotkey modifier/key details for the following items:
---   * `toggleInputSource` - switch between the "Hebrew" and "ABC" layouts.
function obj:bindHotKeys(_mapping)
    local def = {
        toggleInputSource = function()
          setInputSourceOnKeyDown()
        end
    }
    Spoons.bindHotkeysToSpec(def, _mapping)
    return self
end

--- KeyboardLayoutManager:start(ignored)
--- Method
--- Starts the module.
--- Parameters:
---  * `ignored` - A table of bundle IDs of apps for which layout switching should be avoided.
function obj:start(ignored)
  avoidSwitchingInputSourceOnActivation = ignored or {}
  return self
end

function obj:init()
  watcher = Application.watcher.new(setInputSourceOnAppActivation)
  watcher:start()
end

return obj
