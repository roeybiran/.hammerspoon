--- === NotificationCenter ===
---
--- Notification Center automations.
local ui = require("util.ax")
local ax = require("hs.axuielement")
local application = require("hs.application")
local Mouse = require("hs.mouse")
local eventtap = require("hs.eventtap")
local Timer = require("hs.timer")
local FN = require("hs.fnutils")
local hs = hs

local obj = {}

obj.__index = obj
obj.name = "NotificationCenter"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function moveCursorToBanner(theWindow, shouldClick)
	local windowPosition = theWindow:attributeValue("AXPosition")
	local x = windowPosition.x + 40
	local y = windowPosition.y + 40
	local originalPosition = Mouse.absolutePosition()
	local newPosition = { x = x, y = y }
	Mouse.absolutePosition(newPosition)
	if shouldClick then
		eventtap.leftClick(newPosition)
	end
	Timer.doAfter(
		0.5,
		function()
			Mouse.absolutePosition(originalPosition)
		end
	)
end

function obj:toggle()
	ui.getUIElement(
		application("Control Center"),
		{
			{ "AXMenuBar",     1 },
			{ "AXMenuBarItem", 1 }
		}
	):performAction("AXPress")
end

-- the accessibility structure of notifications has changed drastically in Big Sur:
-- all banners are nested under the "AXOpaqueProviderGroup", where each banner is an "AXGroup"
function obj:clickButton(theButton)
	local app = application.applicationsForBundleID("com.apple.notificationcenterui")[1]
	local axApp = ax.applicationElement(app)
	local container =
			ui.getUIElement(
				axApp,
				{
					{ "AXWindow",              1 },
					{ "AXScrollArea",          1 },
					{ "AXOpaqueProviderGroup", 1 }
				}
			):attributeValue("AXChildren")

	local banners =
			FN.filter(
				container,
				function(element)
					return element:attributeValue("AXRole") == "AXGroup"
				end
			)

	for _, banner in ipairs(banners) do
		-- button "3" -> click on the banner and return
		if theButton == 3 then
			moveCursorToBanner(banner, true)
			return
		end

		-- move mouse cursor to the banner to reveal the buttons
		moveCursorToBanner(banner, false)

		Timer.doAfter(
			0.2,
			function()
				local targetButton
				-- the close button
				if theButton == 1 then
					targetButton = ui.getUIElement(banner, { { "AXButton", 1 } })
				end
				-- the "action" button
				if theButton == 2 then
					targetButton = ui.getUIElement(banner, { { "AXButton", 3 } })
				end
				targetButton:performAction("AXPress")
			end
		)

		return

		-- if theButton == 2 then
		--   local button2 = ui.getUIElement(theWindow, {{"AXMenuButton", 1}})
		--   if not button2 then
		--     ui.getUIElement(theWindow, {{"AXButton", 2}}):performAction("AXPress")
		--     return
		--   end
		--   ui.getUIElement(theWindow, {{"AXMenuButton", 1}}):setTimeout(0.2)
		--       :performAction("AXPress")
		--   button2:attributeValue("AXChildren")[1]:attributeValue("AXChildren")[1]:setAttributeValue(
		--       "AXSelected", true)
		-- end
	end
end

--- NotificationCenter:bindHotkeys(_mapping)
--- Method
--- Bind hotkeys for this module. The `_mapping` table keys correspond to the following functionalities:
--- * `firstButton` - clicks on the first (or only) button of a notification center banner. If banners are configured through system preferences to be transient, a mouse move operation will be performed first to try and reveal the button, should it exists.
--- * `secondButton` - clicks on the second button of a notification center banner. If banners are configured through system preferences to be transient, a mouse move operation will be performed first to try and reveal the button, should it exists. If the button is in fact a menu button (that is, it offers a dropdown of additional options), revealing the menu will be favored over a simple click.
--- * `toggle` - reveals the notification center itself (side bar). Once revealed, a second call of this function will switch between the panel's 2 different modes ("Today" and "Notifications"). Closing the panel could be done normally, e.g. by pressing escape.
--- Parameters:
---  * `_mapping` - see the Spoon plugin documentation for the implementation.
function obj:bindHotKeys(_mapping)
	local def = {
		firstButton = function()
			obj:clickButton(1)
		end,
		secondButton = function()
			obj:clickButton(2)
		end,
		thirdButton = function()
			obj:clickButton(3)
		end,
		toggle = function()
			obj:toggle()
		end
	}
	hs.spoons.bindHotkeysToSpec(def, _mapping)
	return self
end

return obj
