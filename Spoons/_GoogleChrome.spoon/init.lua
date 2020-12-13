local osascript = require("hs.osascript")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Chrome"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local _modal = nil
local _appObj = nil

obj.bundleID = "com.google.Chrome"

local function closeOtherTabs()
  osascript.applescript([[
    tell application "Google Chrome"
    tell window 1
      set activeID to the id of its active tab
      set theTabs to every tab
      repeat with i from 1 to count theTabs
        tell item i of theTabs
          if its id is not equal to activeID then
            close
          end if
        end tell
      end repeat
    end tell
  end tell
  ]])
end

local functions = {
  closeOtherTabs = function() closeOtherTabs() end,
}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
      -- print(hs.inspect(v))
      local mods, key = table.unpack(hotkeysTable[k])
      _modal:bind(mods, key, v)
    end
  end
  return self
end

function obj:start(appObj)
  _appObj = appObj
  _modal:enter()
  return self
end

function obj:stop()
  _modal:exit()
  return self
end

function obj:init()
  if not obj.bundleID then
    hs.showError("bundle indetifier for app spoon is nil")
  end
  _modal = Hotkey.modal.new()
  return self
end

return obj
