local Caffeinate = require("hs.caffeinate")
local settings = require("hs.settings")
local menubar = require("hs.menubar")
local Timer = require("hs.timer")

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local obj = {}
local onIcon = script_path() .. "on.pdf"
local menuBarItem = nil
local sessionIsRunningKey = "rbCaffeineSessionIsRunning"
local displaySleepAllowedKey = "rbCaffeineDisplaySleepAllowed"
local sleepTypes = {"systemIdle", "displayIdle"}
local sessionTimeRemaining = 0
local menuBarTimer = nil
local SESSION_RUNNING_DEFAULT = false
local DISPLAY_SLEEP_ALLOWED_DEFAULT = true

local function keepSystemAwake()
  Caffeinate.set("systemIdle", true)
end

local function keepSystemAndDisplayAwake()
  Caffeinate.set("displayIdle", true)
end

local function isCaffeineSessionRunning()
  local currentAssertions = Caffeinate.currentAssertions()
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
  if not menuBarItem then
    local icon = onIcon
    local isTemplate = false
    menuBarItem = menubar.new():setIcon(icon, isTemplate)
  end
  -- if hours then
  --   sessionTimeRemaining = hours * 60 * 60
  --   local timerShouldStopAt = Timer.secondsSinceEpoch() + sessionTimeRemaining
  --   menuBarTimer = Timer.doEvery(1, function()
  --     sessionTimeRemaining = sessionTimeRemaining - 1
  --     menuBarItem:setTitle(sessionTimeRemaining)
  --   end)
  -- end
  if settings.get(displaySleepAllowedKey) then
    keepSystemAwake()
  else
    keepSystemAndDisplayAwake()
  end
  settings.set(sessionIsRunningKey, true)
end

local function endSession()
  if menuBarItem then
    menuBarItem:delete()
    menuBarItem = nil
  end
  for _, v in ipairs(sleepTypes) do
    Caffeinate.set(v, false)
  end
  settings.set(sessionIsRunningKey, false)
end

function obj:stop()
  endSession()
  return self
end

function obj:start()
  beginSession()
  return self
end

function obj:init()
  settings.set(displaySleepAllowedKey, settings.get(displaySleepAllowedKey) or DISPLAY_SLEEP_ALLOWED_DEFAULT)
  settings.set(sessionIsRunningKey, settings.get(sessionIsRunningKey) or SESSION_RUNNING_DEFAULT)
  if settings.get(sessionIsRunningKey) then
    beginSession()
  end
  return self
end

return obj
