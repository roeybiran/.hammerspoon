local ui = require("util.ax")
local config = require("config")

local obj = {}

obj.__index = obj
obj.name = "Globals"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:focusMenuBar()
	hs.axuielement.systemElementAtPosition({ 0, 0 }):attributeValue("AXParent")[2]:performAction("AXPress")
end

function obj:rightClick()
	hs.axuielement.applicationElement(hs.application.frontmostApplication()):attributeValue("AXFocusedUIElement")
			:performAction(
				"AXShowMenu"
			)
end

function obj:focusDock()
	ui.getUIElement(hs.application("Dock"), { { "AXList", 1 } }):setAttributeValue("AXFocused", true)
end

function obj:openTerminal()
	local termBundleID = config.terminal
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
			obj:rightClick()
		end,
		focusMenuBar = function()
			obj:focusMenuBar()
		end,
		focusDock = function()
			obj:focusDock()
		end,
		openTerminal = function()
			obj:openTerminal()
		end
	}
	hs.spoons.bindHotkeysToSpec(def, _mapping)
	return self
end

return obj
