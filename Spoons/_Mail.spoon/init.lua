--- === Mail ===
---
--- Mail.app automations.
local osascript = require("hs.osascript")
local eventtap = require("hs.eventtap")
local geometry = require("hs.geometry")
local ax = require("hs.axuielement")
local ui = require("rb.ui")
local fuzzyChooser = require("rb.fuzzychooser")
local Util = require("rb.util")
local Hotkey = require("hs.hotkey")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Mail"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.bundleID = "com.apple.mail"

local _modal = nil
local _appObj = nil

local function chooserCallback(choice) os.execute(string.format([[/usr/bin/open "%s"]], choice.url)) end

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

local function pane1(appObj)
  -- focus on mailbox list
  local e = ui.getUIElement(appObj, {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}, {"AXOutline", 1}})
  e:setAttributeValue("AXFocused", true)
end

local function pane2(appObj)
  -- focus on messages list
  local msgsList = {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXSplitGroup", 1}, {"AXScrollArea", 1}, {"AXTable", 1}}
  local e = ui.getUIElement(appObj, msgsList)
  e:setAttributeValue("AXFocused", true)
  if not getSelectedMessages() then
    for _ = 1, 2 do
      eventtap.keyStroke({}, "down")
    end
  end
end

local function pane3(appObj)
  -- focus on a specific message
  -- get message's body position
  local msgArea = {
    {"AXWindow", 1},
    {"AXSplitGroup", 1},
    {"AXSplitGroup", 1},
    {"AXScrollArea", 2},
    {"AXGroup", 1},
    {"AXScrollArea", 1},
    {"AXGroup", 1}
  }
  local e = ui.getUIElement(appObj, msgArea)
  -- without a mouse click link highlighting would not work
  local pos = e:attributeValue("AXPosition")
  local point = geometry.point({pos.x + 10, pos.y + 10})
  eventtap.leftClick(point)
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
        {"AXWebArea", 1}
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

local function cycleThroughMessagesList(appObj, direction)
  local messagesContainer = ui.getUIElement(appObj, {
    {"AXWindow", 1},
    {"AXSplitGroup", 1},
    {"AXSplitGroup", 1},
    {"AXScrollArea", 1},
    {"AXTable", 1}
  })
  local messages = messagesContainer:attributeValue("AXChildren")
  local messagesCount = Util.tableCount(messages) - 1 -- decrement header row element
  local selected
  for i, v in ipairs(messages) do
    if v:attributeValue("AXSelected") then
      selected = i
    end
  end

  local newValue
  if direction == "down" then
    newValue = selected + 1
    if newValue > messagesCount then
      newValue = 1
    end
  else
    newValue = selected - 1
    if newValue == 0 then
      newValue = messagesCount
    end
  end

  messagesContainer:setAttributeValue("AXSelectedRows", {messages[newValue]})
end

local functions = {
  pane1 = function() pane1(_appObj) end,
  pane2 = function() pane2(_appObj) end,
  pane3 = function() pane3(_appObj) end,
  getMessageLinks = function() getMessageLinks(_appObj) end,
  selectNextMessage = function() cycleThroughMessagesList(_appObj, "down") end,
  selectPrevMessage = function() cycleThroughMessagesList(_appObj, "up") end
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
