local Console = require("hs.console")
local hs = hs

local obj = {}

obj.modal = nil

obj.actions = {
  clearConsole = {
    action = function() Console.clearConsole() end,
    hotkey = {"cmd", "k"},
  },
  reload = {
    action = function() hs.reload() end,
    hotkey = {"cmd", "r"}
  },
}

function obj:start(_)
  obj.modal:enter()
  return self
end

function obj:stop()
  obj.modal:exit()
  return self
end

return obj
