local hs = hs
local Application = require("hs.application")
local Plist = require("hs.plist")

local plistPath = os.getenv("HOME") .. "/Library/Preferences/com.rb.hs.appquitter.tracker.plist"
local newPlist = {}

hs.printf("AppQuitter SESSION BEGIN")

for bundleIDKey, rulesTable in pairs(Plist.read(plistPath)) do
    local app = Application(bundleIDKey)
    if app and app:isRunning() then
        for operationKey, scheduledTimeValue in pairs(rulesTable) do
            local now = os.time()
            if now > scheduledTimeValue then
                if operationKey == "quit" then
                    app:kill()
                end
                if operationKey == "hide" then
                    app:hide()
                end
                hs.printf("%s => PERFORMING %s", bundleIDKey, operationKey)
            else
                if not newPlist[bundleIDKey] then
                    newPlist[bundleIDKey] = {}
                end
                newPlist[bundleIDKey][operationKey] = scheduledTimeValue
                -- logging
                local units = "minutes"
                local timeDiff = math.floor((scheduledTimeValue - now) / 60)
                if timeDiff > 60 then
                    timeDiff = math.floor(timeDiff / 60)
                    units = "hours"
                end
                hs.printf("%s => scheduled for %s in %s %s", bundleIDKey, operationKey, timeDiff, units)
            end
        end
    end
end

Plist.write(plistPath, newPlist)

hs.printf("AppQuitter SESSION END")
