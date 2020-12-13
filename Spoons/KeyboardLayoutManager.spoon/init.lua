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
local spoon = spoon
local obj = {}

obj.__index = obj
obj.name = "KeyboardLayoutManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local keyboardLayoutSwitcherExcludedApps =
    {"at.obdev.LaunchBar", "com.contextsformac.Contexts"}

-- called when the key to toggle the layout is pressed
local function toggleInputSource()
    local bundleID = Window.frontmostWindow():application():bundleID()
    local currentLayout = Keycodes.currentLayout()
    local newLayout = "ABC"
    if currentLayout == "ABC" then newLayout = "Hebrew" end

    Keycodes.setLayout(newLayout)

    if FNUtils.contains(keyboardLayoutSwitcherExcludedApps, bundleID) then
        return
    end

    if bundleID == "com.apple.Safari" then
        spoon._Safari:saveLayoutForCurrentURL(newLayout)
    end

    local settingsTable = Settings.get("RBAppsLastActiveKeyboardLayouts") or {}
    settingsTable[bundleID] = {
        ["LastActiveKeyboardLayout"] = newLayout,
        ["LastActiveKeyboardLayoutTimestamp"] = os.time()
    }
    Settings.set("RBAppsLastActiveKeyboardLayouts", settingsTable)
end

--- KeyboardLayoutManager:setInputSource(bundleid)
---
--- Method
---
--- Switch to an app's last used keyboard layout. Typically, called in an app watcher callback for the activated app.
---
--- Parameters:
---
---  * `bundleid` - a string, the bundle identifier of the app.
---
function obj:setInputSource(bundleid)
    -- default to abc if no saved setting
    local newLayout = "ABC"
    -- special handling for safari
    local settingsTable = Settings.get("RBAppsLastActiveKeyboardLayouts") or {}
    local appSetting = settingsTable[bundleid]
    if appSetting then
        -- TODO: reset back to abc based on timestamp?
        newLayout = appSetting["LastActiveKeyboardLayout"]
    end
    -- ignore for safari

    if bundleid == "com.apple.Safari" then return end
    Keycodes.setLayout(newLayout)
    return self
end

--- KeyboardLayoutManager:bindHotkeys(mapping)
---
--- Method
---
--- Binds hotkeys for this module
---
--- Parameters:
---
---  * `mapping` - A table containing hotkey modifier/key details for the following items:
---   * `toggleInputSource` - switch between the "Hebrew" and "ABC" layouts.
---
function obj:bindHotKeys(_mapping)
    local def = {toggleInputSource = function() toggleInputSource() end}
    Spoons.bindHotkeysToSpec(def, _mapping)
    return self
end

return obj
