local osascript = require("hs.osascript")
local ax = require("hs.axuielement")
local ui = require("rb.ui")
local fuzzyChooser = require("rb.fuzzychooser")
local Util = require("rb.util")
local Hotkey = require("hs.hotkey")
local hs = hs
local FN = require("hs.fnutils")

local obj = {}
obj.modal = nil
local _appObj = nil


local function chooserCallback(choice)
os.execute(string.format([[/usr/bin/open "%s"]], choice.url))
end

local function getSelectedMessages()
local _, messageIds, _ = osascript.applescript([[
set msgId to {}
tell application "Mail" to set _selected to selection
repeat with i from 1 to (count _selected)
  set end of msgId to id of item i of _selected
end repeat
  return msgId
  ]])
  local next = next
  if not next(messageIds) then
    return nil
  else
    return messageIds
  end
end

local function getMessageLinks(appObj)
  local window = ax.windowElement(appObj:focusedWindow())
  -- when viewed in the main app OR when viewed in a standalone container
  local messageWindow = ui.getUIElement(window, ({{"AXSplitGroup", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 2}})) or
  ui.getUIElement(window, ({{"AXScrollArea", 1}}))
  local messageContainers = messageWindow:attributeValue("AXChildren")
  local choices = {}
  for _, messageContainer in ipairs(messageContainers) do
    if messageContainer:attributeValue("AXRole") == "AXGroup" then
      local webArea = ui.getUIElement(messageContainer, {
        {"AXScrollArea", 1},
        {"AXGroup", 1},
        {"AXGroup", 1},
        {"AXScrollArea", 1},
        {"AXWebArea", 1},
      })
      local links = webArea:attributeValue("AXLinkUIElements")
      for _, v in ipairs(links) do
        local title = v:attributeValue("AXTitle")
        local url = v:attributeValue("AXURL").url
        table.insert(choices, {url = url, text = title or url, subText = url})
      end
    end
  end
  if Util.tableCount(choices) == 0 then
    table.insert(choices, {text = "No Links"})
  end
  fuzzyChooser:start(chooserCallback, choices, {"text", "subText"})
end

-- TODO: move to ./rb
local function _navigateThroughGenericList(list, direction)
  local children = list:attributeValue("AXChildren")
  local childrenCount = Util.tableCount(children) - 1 -- decrement header row element
  local newValue = 1 -- default to no selection -> select the first child
  local selectedChild = FN.find(children, function(e)
    return e:attributeValue("AXSelected")
  end)
  if selectedChild then
    local selectedIndex = FN.indexOf(children, selectedChild)
    if direction == "down" then
      newValue = selectedIndex + 1
      if newValue > childrenCount then
        newValue = 1
      end
    else
      newValue = selectedIndex - 1
      if newValue == 0 then
        newValue = childrenCount
      end
    end
  end
  list:setAttributeValue("AXSelectedRows", {children[newValue]})
end

local function cycleThroughMessagesList(appObj, direction)
  local messagesContainer = ui.getUIElement(appObj, {
    {"AXWindow", 1},
    {"AXSplitGroup", 1},
    {"AXSplitGroup", 1},
    {"AXScrollArea", 1},
    {"AXTable", 1},
  })
  _navigateThroughGenericList(messagesContainer, direction)

end

obj.actions = {
  selectNextMessage = {
    action = function()
      cycleThroughMessagesList(_appObj, "down")
    end,
    hotkey = {"ctrl", "tab"}
  },
  selectPrevMessage = {
    action = function()
      cycleThroughMessagesList(_appObj, "up")
    end,
    hotkey = {{"ctrl", "shift"}, "tab"}
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
