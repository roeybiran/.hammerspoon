local UI = require("rb.ui")
local Util = require("rb.util")
local fuzzyChooser = require("rb.fuzzychooser")

local obj = {}

obj.modal = nil
local _appObj = nil

local function chooserCallback(choice)
  os.execute(string.format([["/usr/bin/open" "%s"]], choice.text))
end

local function getChatMessageLinks(appObj)
  local linkElements = UI.getUIElement(appObj:mainWindow(), {
    {"AXSplitGroup", 1},
    {"AXScrollArea", 2},
    {"AXWebArea", 1}
  }):attributeValue("AXLinkUIElements")
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

obj.actions = {
  getMessageLinks = {
    action = function() getChatMessageLinks(_appObj) end,
    hotkey = {"alt", "o"}
  },
  deleteConversation = {
    action = function() _appObj:selectMenuItem({"File", "Delete Conversation…"}) end,
    hotkey =   {"cmd", "delete"},
  },
}

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
