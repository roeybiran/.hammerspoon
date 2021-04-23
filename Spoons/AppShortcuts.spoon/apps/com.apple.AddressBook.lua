local ax = require("hs.axuielement")
local ui = require("rb.ui")

local obj = {}
obj.modal = nil
local _appObj = nil

local function performContactAction(appObj, button)
  local win = ax.windowElement(appObj:focusedWindow())
  local btn = ui.getUIElement(win, {{"AXSplitGroup", 1}, {"AXButton", button}})
  btn:performAction("AXPress")
end

local functions = {
  contactAction1 = function()
    performContactAction(_appObj, 4)
  end,
  contactAction2 = function()
    performContactAction(_appObj, 5)
  end,
  contactAction3 = function()
    performContactAction(_appObj, 6)
  end,
  contactAction4 = function()
    performContactAction(_appObj, 7)
  end,
}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
      -- print(hs.inspect(v))
      local mods, key = table.unpack(hotkeysTable[k])
      obj.modal:bind(mods, key, v)
    end
  end
  return self
end

function obj:start(appObj)
  _appObj = appObj
  obj.modal:enter()
  return self
end

function obj:stop()
  obj.modal:exit()
  return self
end

return obj