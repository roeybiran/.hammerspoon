local Hotkey = require("hs.hotkey")
local UI = require("rb.ui")
local Util = require("rb.util")
local fuzzyChooser = require("rb.fuzzychooser")
local hs = hs

local obj = {}
local _modal = nil
local _appObj = nil

obj.bundleID = "com.apple.iChat"

local function chooserCallback(choice)
  os.execute(string.format([["/usr/bin/open" "%s"]], choice.text))
end

local function getChatMessageLinks(appObj)
  local linkElements =
      UI.getUIElement(appObj:mainWindow(), {{"AXSplitGroup", 1}, {"AXScrollArea", 2}, {"AXWebArea", 1}}):attributeValue(
          "AXLinkUIElements")
  local choices = {}
  for _, link in ipairs(linkElements) do
    local url = link:attributeValue("AXChildren")[1]:attributeValue("AXValue")
    table.insert(choices, {text = url})
  end
  if Util.tableCount(choices) == 0 then
    table.insert(choices, {text = "No Links"})
  end
  fuzzyChooser:start(chooserCallback, choices, {"text"})
end

local functions = {
  getMessageLinks = function()
    getChatMessageLinks(_appObj)
  end,
}

function obj:bindModalHotkeys(hotkeysTable)
  for k, v in pairs(functions) do
    if hotkeysTable[k] then
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
