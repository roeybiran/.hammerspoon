--- === AppAutomations ===
---
--- Global app automation functions
local Application = require("hs.application")
local geometry = require("hs.geometry")
local osascript = require("hs.osascript")
local ax = require("hs.axuielement")
local ui = require("util.ax")
local Util = require("util.util")

local obj = {}

obj.__index = obj
obj.name = "AppAutomations"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
	return self
end

-- Helper functions (local)
local function finderRightSizeColumn(arg)
	local appObj = Application.get("com.apple.finder")
	if not appObj then return end
	
	local _, currentView, _ = osascript.applescript("tell application \"Finder\" to return current view of window 1")
	local axApp = ax.applicationElement(appObj)
	local x, y, coords, modifiers
	
	if currentView == "clvw" then
		coords = axApp:attributeValue("AXFocusedUIElement"):attributeValue("AXParent"):attributeValue("AXFrame")
		x = (coords.x + coords.w) - 10
		y = (coords.y + coords.h) - 10
	elseif currentView == "lsvw" then
		arg = "this"
		local firstColumn = ui.getUIElement(appObj, {
			{ "AXWindow",     1 },
			{ "AXSplitGroup", 1 },
			{ "AXSplitGroup", 1 },
			{ "AXScrollArea", 1 },
			{ "AXOutline",    1 },
			{ "AXGroup",      1 },
			{ "AXButton",     1 },
		})
		coords = firstColumn:attributeValue("AXFrame")
		x = coords.x + coords.w
		y = coords.y + (coords.h / 2)
	end
	
	local point = geometry.point({ x, y })
	if arg == "this" then
		modifiers = nil
	elseif arg == "all" then
		modifiers = { alt = true }
	end
	Util.doubleLeftClick(point, modifiers, true)
end

-- Global Finder functions
function finderOpenPackage()
	osascript.applescript([[
		tell application "Finder"
			set theSelection to selection
			set thePaths to {}
			repeat with i from 1 to count theSelection
				set theSelected to item i of theSelection
				try
					set theTarget to folder "Contents" of theSelected
				on error
					set theTarget to theSelected
				end try
				set end of thePaths to theTarget
			end repeat
			if (count of thePaths) is 1 then
				set target of Finder window 1 to (item 1 of thePaths)
				return
			end if
			if (count of thePaths) > 1 then
				open thePaths as alias list
			end if
		end tell
	]])
end

function finderShowOriginal()
	local appObj = Application.get("com.apple.finder")
	if appObj then
		appObj:selectMenuItem({ "File", "Show Original" })
	end
end

function finderOpenInNewTab()
	local appObj = Application.get("com.apple.finder")
	if appObj then
		appObj:selectMenuItem({ "File", "Open in New Tab" })
	end
end

function finderRightSizeAllColumns()
	finderRightSizeColumn("all")
end

function finderRightSizeThisColumn()
	finderRightSizeColumn("this")
end

-- Helper functions (local)
local function activityMonitorRadioButton(buttonNumber)
	local appObj = Application.get("com.apple.ActivityMonitor")
	if not appObj or not appObj:mainWindow() then return end
	
	ui.getUIElement(ax.windowElement(appObj:mainWindow()), {
		{"AXToolbar", 1},
		{"AXGroup", 2},
		{"AXRadioGroup", 1},
		{"AXRadioButton", tonumber(buttonNumber)}
	}):performAction("AXPress")
end

-- Global Activity Monitor functions
function activityMonitorRadioButton1()
	activityMonitorRadioButton(1)
end

function activityMonitorRadioButton2()
	activityMonitorRadioButton(2)
end

function activityMonitorRadioButton3()
	activityMonitorRadioButton(3)
end

function activityMonitorRadioButton4()
	activityMonitorRadioButton(4)
end

function activityMonitorRadioButton5()
	activityMonitorRadioButton(5)
end

function activityMonitorQuitProcess()
	local appObj = Application.get("com.apple.ActivityMonitor")
	if appObj then
		appObj:selectMenuItem({"View", "Quit Process"})
	end
end

return obj
