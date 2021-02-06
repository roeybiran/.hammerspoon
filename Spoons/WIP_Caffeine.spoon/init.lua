local caffeine = require("hs.caffeinate")
local settings = require("hs.settings")
local menubar = require("hs.menubar")
local FN = require("hs.fnutils")
local Timer = require("hs.timer")

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local obj = {}
local DURATIONS = {1, 2, 4, 6, 8, 10}
local sessionTimeRemaining = 0
local onIcon = script_path() .. "on.pdf"
local offIcon = script_path() .. "off.pdf"
local menuBarItem = nil

local sleepPreventionTypes = {systemOnly = "systemIdle", systemAndDisplay = "displayIdle"}
local menuBarTimer

local sessionIsRunningKey = "rbCaffeineSessionIsRunning"
local displaySleepAllowedKey = "rbCaffeineDisplaySleepAllowed"

local function getSleepType()
  if allowDisplaySleep then
    return sleepPreventionTypes.systemOnly
  end
  return sleepPreventionTypes.systemAndDisplay
end

local function isCaffeineSessionRunning()
  local currentAssertions = caffeine.currentAssertions()
  for key, _ in pairs(currentAssertions) do
    for _, v in ipairs(currentAssertions[key]) do
      if v.AssertName == "hs.caffeinate" then
        -- print(v)
        return true
      end
    end
  end
end

local function beginSession(hours)
  if hours then
    sessionTimeRemaining = hours * 60 * 60
    local timerShouldStopAt = Timer.secondsSinceEpoch() + sessionTimeRemaining
    menuBarTimer = Timer.doEvery(1, function()
      sessionTimeRemaining = sessionTimeRemaining - 1
      menuBarItem:setTitle(sessionTimeRemaining)
    end)
  end
  menuBarItem:setIcon(onIcon, false)
  -- local displaySleepAllowed =
  caffeine.set(getSleepType(), true)
  settings.set(sessionIsRunningKey, true)
end

local function endSession()
  -- menuBarTimer:stop()
  -- menuBarItem:setTitle("")
  for k, _ in pairs(sleepPreventionTypes) do
    caffeine.set(sleepPreventionTypes[k], false)
  end
  settings.set(sessionIsRunningKey, false)
end

local function opts()
  local title = "Start"
  local action = function()
    beginSession()
  end
  if isCaffeineSessionRunning() then
    title = "Stop"
    action = function()
      endSession()
    end
  end
  return {
    {title = title, fn = action},
    {
      title = "Quit",
      fn = function()
        obj:stop()
      end,
    },
    {title = "-"},
    {
      title = "Allow Display Sleep",
      checked = settings.get(displaySleepAllowedKey),
      fn = function()
        settings.set(displaySleepAllowedKey, (not settings.get(displaySleepAllowedKey)))
        if isCaffeineSessionRunning() then
          endSession()
          beginSession()
        end
      end,
    },
    {title = "-"},
    -- durations
    table.unpack(FN.imap(DURATIONS, function(dur)
      return {
        title = string.format("Run for %s hours", dur),
        fn = function()
          beginSession(tonumber(dur))
        end,
      }
    end)),
  }
end

local function setupMenu()
  if not menuBarItem then
    menuBarItem = menubar.new():setIcon(offIcon, true):setMenu(opts)
  end
end

-- quits the module
function obj:stop()
  obj:endSession()
  if menuBarItem then
    menuBarItem:delete()
  end
  return self
end

-- starts the module (shows the menu item), but not necessarily starts the session
function obj:start()
  setupMenu()
  return self
end

function obj:init()
  settings.set(displaySleepAllowedKey, settings.get(displaySleepAllowedKey) or true)
  setupMenu()
  if settings.get(sessionIsRunningKey) then
    setupMenu()
    obj:start()
  end
  return self
end

return obj
