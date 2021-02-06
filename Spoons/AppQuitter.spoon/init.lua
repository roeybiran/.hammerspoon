--- === AppQuitter ===
---
--- Leverages `launchd` to quit and/or hide inactive apps.
--- DO NOT activate this module if you don't plan on using it along with `hs.application.watcher`, this module relies on it exclusively to update its scheduled actions as apps go in and out of focus. Without it, the timers will quickly go out of sync.
--- Ideally, this module's `update` method will be called in each callback of `hs.application.watcher`.
---
local Application = require("hs.application")
local FS = require("hs.fs")
local Plist = require("hs.plist")
local Timer = require("hs.timer")
local FnUtils = require("hs.fnutils")
local AppleScript = require("hs.osascript").applescript
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "AppQuitter"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local rules = {}
local TIMERS_PLIST_PATH = os.getenv("HOME") .. "/Library/Preferences/com.rb.hs.appquitter.tracker.plist"
local appWatcher = nil

function obj.log()
  for line in io.lines(os.getenv("HOME") .. "/Library/Logs/com.rb.hs.appquitter.errors.log") do
    print(line)
  end
end

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local function updateIntervalsForBackgroundLaunchedOrDeactivatedApp(bundleID)
  if not bundleID or not rules[bundleID] then
    return
  end
  -- the sole purpose of this function is to start/update the timer
  -- when an app is deactivated or launched (in the background).
  local now = os.time()
  local quitInterval = now + rules[bundleID].quit
  local hideInterval = now + rules[bundleID].hide
  local timersPlist = Plist.read(TIMERS_PLIST_PATH)
  if not timersPlist then
    timersPlist = {}
  end
  if not timersPlist[bundleID] then
    timersPlist[bundleID] = {}
  end
  timersPlist[bundleID] = {quit = quitInterval, hide = hideInterval}
  Plist.write(TIMERS_PLIST_PATH, timersPlist)
end

--- AppQuitter:update(event, bundleID)
---
--- Method
---
--- Updates the module's timers.
---
--- Parameters:
---
---  * `event` - A string, one of the `hs.application.watcher` event constants.
---  * `bundleID` - A string, the bundle identifier of event-triggering app.
---
function obj:update(event, bundleID)
  -- bail out if app is blacklisted
  if event == Application.watcher.deactivated or event == Application.watcher.launched then
    updateIntervalsForBackgroundLaunchedOrDeactivatedApp(bundleID)
  end
  return self
end

--- AppQuitter:start([rules])
---
--- Method
---
--- Sets up and starts the module. Begins the tracking of running dock apps,
--- or resumes tracking of a given app if its timer is already running.
---
--- Parameters:
---
--- * `rules` - a table that defines inactivity periods after which an app will hide/quit. Each element must be one of 2 forms:
---     * a key value pair. Each key should equal to the bundle identifier string of the app you wish to set rules for.
---       * Each value must be a table containing exactly 2 key value pairs: (1) The keys, which are strings, should be named "quit" and "hide".
---       * The values for each keys are integers, and they should correspond to the period (in hours) of inactivity before an action takes place.
---       * For example: ["com.apple.Safari"] = {quit = 1, hide = 0.2}. This will set a rule for Safari to quit after 1 hour and hide after 12 minutes.
---     * a simple string representing that target app's bundle identifier. In this case, the default hide/quit values will be applied.
---
--- Returns:
---
--- * the module object, for method chaining
---
function obj:start(config)
  appWatcher:start()
  local launchdRunInterval = config.launchdRunInterval
  local launchdLabel = "com.rb.hs.appquitter.daemon"
  local launchdPlistPath = os.getenv("HOME") .. "/Library/LaunchAgents/" .. launchdLabel .. ".plist"
  local launchdPlistObject = {
    Label = launchdLabel,
    StartInterval = tonumber(launchdRunInterval),
    ProgramArguments = {"/usr/local/bin/appquitter"},
    StandardErrorPath = os.getenv("HOME") .. "/Library/Logs/com.rb.hs.appquitter.errors.log",
    StandardOutPath = os.getenv("HOME") .. "/Library/Logs/com.rb.hs.appquitter.log",
  }

  local launchdPlistExists = FS.displayName(launchdPlistPath) ~= nil

  local shouldUpdateLaunchdPlist = false
  if launchdPlistExists then
    local currentPlist = Plist.read(launchdPlistPath)
    for property, _ in pairs(launchdPlistObject) do
      if launchdPlistObject[property] ~= currentPlist[property] then
        shouldUpdateLaunchdPlist = true
        os.execute(string.format([[/bin/launchctl unload "%s"]], launchdPlistPath))
        break
      end
    end
  end

  if not launchdPlistExists or shouldUpdateLaunchdPlist then
    Plist.write(launchdPlistPath, launchdPlistObject)
  end

  -- tracker plist
  local secsSinceBoot = Timer.absoluteTime() * (10 ^ -9)
  local shouldCleanUp = secsSinceBoot < 50
  if not FS.displayName(TIMERS_PLIST_PATH) or shouldCleanUp then
    Plist.write(TIMERS_PLIST_PATH, {})
  end

  -- script executed by launchd
  local launchdScriptDst = "/usr/local/bin/appquitter"
  os.remove(launchdScriptDst)
  FS.link(script_path() .. "launchd.py", launchdScriptDst, true)

  local stdout, _, _, _ = hs.execute("/bin/launchctl list")
  local isJobLoaded = string.match(stdout, launchdLabel)
  if not isJobLoaded then
    os.execute(string.format([[/bin/launchctl load "%s"]], launchdPlistPath))
  end

  local appsWithRunningTimers = {}
  local timersPlist = Plist.read(TIMERS_PLIST_PATH) or {}
  for appID, _ in pairs(timersPlist) do
    table.insert(appsWithRunningTimers, appID)
  end

  -- load rules
  local DEFAULT_QUIT_INTERVAL = config.defaultQuitInterval
  local DEFAULT_HIDE_INTERVAL = config.defaultHideInterval
  for key, value in pairs(config.rules) do
    if tonumber(key) then
      rules[value] = {quit = DEFAULT_QUIT_INTERVAL, hide = DEFAULT_HIDE_INTERVAL}
    else
      rules[key] = {
        -- convert to seconds
        quit = value.quit * (60 * 60),
        hide = value.hide * (60 * 60),
      }
    end
  end

  local _, dockApps, _ = AppleScript [[
        tell app "System Events" to return the bundle identifier of every application process whose background only is false
        ]]
  for _, appID in ipairs(dockApps) do
    if not FnUtils.contains(appsWithRunningTimers, appID) then
      updateIntervalsForBackgroundLaunchedOrDeactivatedApp(appID)
    end
  end

  return self
end

function obj:init()
  appWatcher = Application.watcher.new(function(_, event, appObj)
    if appObj then
      obj:update(event, appObj:bundleID())
    end
  end)
  return self
end

return obj
