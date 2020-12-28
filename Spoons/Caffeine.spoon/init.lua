local caffeine = require("hs.caffeinate")
local settings = require("hs.settings")
local menubar = require("hs.menubar")

local obj = {}

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local iconFile = script_path() .. "eye.pdf"
local menuBarIcon = nil
local allowDisplaySleep = true
local sleepTypes = {preventSystemSleepOnly = "systemIdle", preventSystemAndDisplay = "displayIdle"}

local function getSleepType()
  if allowDisplaySleep then
    return sleepTypes.preventSystemSleepOnly
  end
  return sleepTypes.preventSystemAndDisplay
end

function obj:init()
  if settings.get("isCaffeineSessionRunning") then
    obj:start()
  end
  return self
end

function obj:start(duration)
  if not menuBarIcon then
    menuBarIcon = menubar.new():setIcon(iconFile, true)
  end
  caffeine.set(getSleepType(), true)
  settings.set("isCaffeineSessionRunning", true)
  return self
end

function obj:stop()
  if menuBarIcon then
    menuBarIcon:delete()
  end
  caffeine.set(getSleepType(), false)
  settings.set("isCaffeineSessionRunning", false)
  return self
end

return obj
