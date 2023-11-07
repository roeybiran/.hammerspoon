--- === Globals ===
---
--- Various hotkey-bound automations that are not app-specific.
local application = require("hs.application")
local ax = require("hs.axuielement")
local UI = require("util.ax")
local Keycodes = require("hs.keycodes")

local hs = hs

local obj = {}

obj.__index = obj
obj.name = "Globals"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function focusMenuBar()
	ax.systemElementAtPosition({0, 0}):attributeValue("AXParent")[2]:performAction("AXPress")
end

local function rightClick()
	ax.applicationElement(application.frontmostApplication()):attributeValue("AXFocusedUIElement"):performAction(
		"AXShowMenu"
	)
end

local function focusDock()
	UI.getUIElement(application("Dock"), {{"AXList", 1}}):setAttributeValue("AXFocused", true)
end

local function openTerminal()
	local termBundleID = "com.googlecode.iterm2"
	local app = hs.application.get(termBundleID)
	if app and app:isFrontmost() then
		app:hide()
	else
		hs.application.launchOrFocusByBundleID(termBundleID)
	end
end
--- Globals:bindHotKeys(_mapping)
--- Method
--- This module offers the following functionalities:
---   * rightClick - simulates a control-click on the currently focused UI element.
---   * focusMenuBar - clicks the menu bar item that immediately follows the  menu bar item.
---   * focusDock - shows the system-wide dock.
--- Parameters:
---   * `_mapping` - A table that conforms to the structure described in the Spoon plugin documentation.
function obj:bindHotKeys(_mapping)
	local def = {
		rightClick = function()
			rightClick()
		end,
		focusMenuBar = function()
			focusMenuBar()
		end,
		focusDock = function()
			focusDock()
		end,
		openTerminal = function()
			openTerminal()
		end
	}
	hs.spoons.bindHotkeysToSpec(def, _mapping)
	return self
end

return obj
