--- === HammerspoonConsole ===
---
--- Hammerspoon (console) automations
local Hotkey = require("hs.hotkey")
local Console = require("hs.console")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Hammerspoon"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.bundleID = "org.hammerspoon.Hammerspoon"

local _modal = nil

local functions = {clearConsole = function() Console.clearConsole() end, reload = function() hs.reload() end}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
      local mods, key = table.unpack(hotkeysTable[k])
      _modal:bind(mods, key, v)
    end
  end
  return self
end

function obj:start(_)
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
