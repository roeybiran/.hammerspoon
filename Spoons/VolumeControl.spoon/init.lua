--- === VolumeControl ===
---
--- Clicks on the "volume" status bar item to reveal its volume slider, and enters a modal that allows to control the slider with the arrow keys.
local Application = require("hs.application")
local Hotkey = require("hs.hotkey")
local AudioDevice = require("hs.audiodevice")
local AX = require("hs.axuielement")
local Observer = require("hs.axuielement").observer
local UI = require("rb.ui")
local Timer = require("hs.timer")

local obj = {}

obj.__index = obj
obj.name = "VolumeControl"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local modal = nil
local observer = nil
local slider = nil

local function modifyVolume(direction, withRepeat)
	for _ = 1, withRepeat do
		if direction == "up" then
			slider:performAction("AXIncrement")
		else
			slider:performAction("AXDecrement")
		end
	end
end

local function observerCallback()
	observer:stop()
	modal:exit()
	observer = nil
	slider = nil
end

--- VolumeControl:start()
--- Method
--- Activates the modules and enters the  modal. The following hotkeys/functionalities are available:
---   * →: increase volume by a level.
---   * ←: decrease volume by a level.
---   * ⇧→: increase volume by a couple of levels.
---   * ⇧←: decrease volume by a couple of levels.
---   * ⌥→: set volume to 100.
---   * ⌥←: set volume to 0.
---   * escape: close the volume menu and exit the modal (the modal will be exited anyway as soon as the volume menu is closed).
function obj:start()
	local app = Application("Control Center")
	local axApp = AX.applicationElement(app)
	-- click on the menu bar item to reveal the window + slider
	UI.getUIElement(axApp, {{"AXMenuBar", 1}, {"AXMenuBarItem", "AXTitle", "Sound"}}):performAction("AXPress")
	Timer.doAfter(
		0.2,
		function()
			slider = UI.getUIElement(axApp, {{"AXWindow", 1}, {"AXGroup", 1}, {"AXSlider", 1}})
			if not slider then
				return
			end
			modal:enter()
			observer = Observer.new(app:pid()):addWatcher(axApp, "AXUIElementDestroyed"):callback(observerCallback):start()
		end
	)
	return self
end

function obj:init()
	modal = Hotkey.modal.new()
	local hotkeySettings = {
		{
			{},
			"right",
			function()
				modifyVolume("up", 1)
			end,
			nil,
			function()
				modifyVolume("up", 1)
			end
		},
		{
			{},
			"left",
			function()
				modifyVolume("down", 1)
			end,
			nil,
			function()
				modifyVolume("down", 1)
			end
		},
		{
			{"shift"},
			"right",
			function()
				modifyVolume("up", 4)
			end
		},
		{
			{"shift"},
			"left",
			function()
				modifyVolume("down", 4)
			end
		},
		{
			{"alt"},
			"right",
			function()
				AudioDevice.defaultOutputDevice():setVolume(100)
			end
		},
		{
			{"alt"},
			"left",
			function()
				AudioDevice.defaultOutputDevice():setVolume(0)
			end
		}
	}
	for _, v in ipairs(hotkeySettings) do
		modal:bind(table.unpack(v))
	end
	return self
end

return obj
