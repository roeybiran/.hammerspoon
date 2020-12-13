--- === AppSpoonsManager ===
---
--- Manages the activation and deactivation of the app-specific Spoons when an app goes in and out of focus, respectively.
local spoon = spoon

local obj = {}

obj.__index = obj
obj.name = "AppSpoonsManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- AppSpoonsManager:update(appObj, bundleID)
---
--- Method
---
--- Calls the `start()` method of the Spoon for the focused app, and calls `exit()` on all other Spoons. This method must be called in each callback of your `hs.application.watcher` instance.
---
--- Parameters:
---
---  * `appObj` - the `hs.application` object of the frontmost app.
---  * `bundleID` - a string, the bundle identifier of the frontmost app.
---
function obj:update(appObj, bundleID)
    for spoonName, spoonContents in pairs(spoon) do
        if spoonContents.bundleID and spoonContents.bundleID == bundleID then
            spoon[spoonName]:start(appObj)
        elseif spoonContents.bundleID then
            spoon[spoonName]:stop()
        end
    end
    return self
end

return obj
