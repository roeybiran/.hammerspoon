--- === VolumeControl ===
---
--- Clicks on the "volume" status bar item to reveal its volume slider, and enters a modal that allows to control the slider with the arrow keys.
local Hotkey = require("hs.hotkey")

local obj = {}

obj.__index = obj
obj.name = "VolumeControl"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local modal = nil
local VOLUME_NOTCHES = 16
local Eventtap = require("hs.eventtap")

local function systemKey(key)
	Eventtap.event.newSystemKeyEvent(string.upper(key), true):post()
	Eventtap.event.newSystemKeyEvent(string.upper(key), false):post()
end

local function modifyVolume(direction, withRepeat)
	for _ = 1, withRepeat do
		if direction == "up" then
			systemKey("SOUND_UP")
		else
			systemKey("SOUND_DOWN")
		end
	end
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
	modal:enter()
end

function obj:stop()
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
				modifyVolume("up", VOLUME_NOTCHES)
			end
		},
		{
			{"alt"},
			"left",
			function()
				modifyVolume("down", VOLUME_NOTCHES)
			end
		}
	}
	modal:bind(
		{},
		"escape",
		nil,
		function()
			modal:exit()
			hs.alert.show("Volume Control Off", nil, nil, 0.3)
		end,
		nil,
		nil
	)
	modal:bind(
		{},
		"return",
		nil,
		function()
			modal:exit()
			hs.alert.show("Volume Control Off", nil, nil, 0.3)
		end,
		nil,
		nil
	)
	for _, v in ipairs(hotkeySettings) do
		modal:bind(table.unpack(v))
	end
	return self
end

return obj
