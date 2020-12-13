--- === NotificationCenter ===
---
--- Notification Center automations.
local ui = require("rb.ui")
local ax = require("hs.axuielement")
local application = require("hs.application")
local Mouse = require("hs.mouse")
local eventtap = require("hs.eventtap")
local geometry = require("hs.geometry")
local Timer = require("hs.timer")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "NotificationCenter"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function getWindow()
  local notifCenterPanel = application.applicationsForBundleID("com.apple.notificationcenterui")[1]:focusedWindow()
  if notifCenterPanel then
    return ax.windowElement(notifCenterPanel)
  end
end

local function toggle()
  -- local currentMousePos = Mouse.getAbsolutePosition()
  -- local iconPos =
  --     ui.getUIElement(application("Control Center"), {{"AXMenuBar", 1}, {"AXMenuBarItem", 1}}):attributeValue(
  --         "AXPosition")
  -- local x = iconPos.x + 10
  -- local y = iconPos.y + 10
  -- eventtap.leftClick(geometry.point({x, y}))
  -- Mouse.setAbsolutePosition(currentMousePos)
    ui.getUIElement(application("Control Center"), {{"AXMenuBar", 1}, {"AXMenuBarItem", 1}}):performAction("AXPress")
end

local function clickButton(theButton)
  local app = application.applicationsForBundleID("com.apple.notificationcenterui")[1]
  local axApp = ax.applicationElement(app)
  local allWindows = axApp:attributeValue("AXChildren")
  for _, theWindow in ipairs(allWindows) do
    local button1 = ui.getUIElement(theWindow, {{"AXButton", 1}})
    -- checking for a banner/alert style notification
    -- if a banner, move mouse cursor to reveal the buttons
    -- "button" 3 -> click on the banner and return
    if not button1 or theButton == 3 then
      local windowPosition = theWindow:attributeValue("AXPosition")
      local x = windowPosition.x + 10
      local y = windowPosition.y + 10
      local originalPosition = Mouse.getAbsolutePosition()
      local newPosition = {x = x, y = y}
      Mouse.setAbsolutePosition(newPosition)
      button1 = ui.getUIElement(theWindow, {{"AXButton", 1}})
      Timer.doAfter(0.5, function() Mouse.setAbsolutePosition(originalPosition) end)
      if theButton == 3 then
        eventtap.leftClick(newPosition)
        return
      end
    end
    if button1 then
      if theButton == 1 then
        button1:performAction("AXPress")
        return
      end
      if theButton == 2 then
        local button2 = ui.getUIElement(theWindow, {{"AXMenuButton", 1}})
        if not button2 then
          ui.getUIElement(theWindow, {{"AXButton", 2}}):performAction("AXPress")
          return
        end
        ui.getUIElement(theWindow, {{"AXMenuButton", 1}}):setTimeout(0.2):performAction("AXPress")
        button2:attributeValue("AXChildren")[1]:attributeValue("AXChildren")[1]:setAttributeValue("AXSelected", true)
      end
    end
  end
end

--- NotificationCenter:bindHotkeys(_mapping)
---
--- Method
---
--- Bind hotkeys for this module. The `_mapping` table keys correspond to the following functionalities:
--- * `firstButton` - clicks on the first (or only) button of a notification center banner. If banners are configured through system preferences to be transient, a mouse move operation will be performed first to try and reveal the button, should it exists.
--- * `secondButton` - clicks on the second button of a notification center banner. If banners are configured through system preferences to be transient, a mouse move operation will be performed first to try and reveal the button, should it exists. If the button is in fact a menu button (that is, it offers a dropdown of additional options), revealing the menu will be favored over a simple click.
--- * `toggle` - reveals the notification center itself (side bar). Once revealed, a second call of this function will switch between the panel's 2 different modes ("Today" and "Notifications"). Closing the panel could be done normally, e.g. by pressing escape.
---
--- Parameters:
---
---  * `_mapping` - see the Spoon plugin documentation for the implementation.
---
function obj:bindHotKeys(_mapping)
  local def = {
    firstButton = function() clickButton(1) end,
    secondButton = function() clickButton(2) end,
    thirdButton = function() clickButton(3) end,
    toggle = function() toggle() end
  }
  hs.spoons.bindHotkeysToSpec(def, _mapping)
  return self
end

return obj
