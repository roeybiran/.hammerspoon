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
local iconFile = script_path() .. "eye.pdf"
local menuBarItem = nil
local allowDisplaySleep = true
local sleepPreventionTypes = {
  systemOnly = "systemIdle",
  systemAndDisplay = "displayIdle",
}
local menuBarTimer

local function getSleepType()
  if allowDisplaySleep then
    return sleepPreventionTypes.systemOnly
  end
  return sleepPreventionTypes.systemAndDisplay
end

local function beginSession(hours)
  sessionTimeRemaining = hours * 60 * 60
  local timerShouldStopAt = Timer.secondsSinceEpoch() + sessionTimeRemaining
  menuBarTimer = Timer.doEvery(1, function()
    sessionTimeRemaining = sessionTimeRemaining - 1
    menuBarItem:setTitle(sessionTimeRemaining)
  end)
  caffeine.set(getSleepType(), true)
  settings.set("isCaffeineSessionRunning", true)
end

local function endSession()
  menuBarTimer:stop()
  menuBarItem:setTitle("")
  caffeine.set(getSleepType(), false)
  settings.set("isCaffeineSessionRunning", false)
end

local function setupMenu()
  local durations = FN.imap(DURATIONS, function(dur)
    return {
      title = string.format("Run for %s hours", dur),
      fn = function() beginSession(tonumber(dur)) end,
    }
  end)
  local opts = {
    {title = "Stop", fn = function() endSession() end},
    {title = "Quit", fn = function() obj:stop() end},
    {title = "-"},
    {title = "Allow Display Sleep", checked = true},
    {title = "-"},
    table.unpack(durations),
  }
  if not menuBarItem then
    menuBarItem = menubar.new():setIcon(iconFile, true):setMenu(opts)
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
  if settings.get("isCaffeineSessionRunning") then
    setupMenu()
    obj:start()
  end
  return self
end

return obj
