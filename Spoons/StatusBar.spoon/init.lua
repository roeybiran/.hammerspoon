--- === StatusBar ===
---
--- Enables a status menu item with the familiar Hammerspoon logo, but with customizable contents and a flashing mode to signal ongoing operations.

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

local obj = {}

obj.__index = obj
obj.name = "StatusBar"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.menuBarItem = nil
local iconPath = script_path() .. "/statusicon.pdf"

function obj:start()
	obj.menuBarItem =
		hs.menubar.new():setIcon(iconPath):setMenu(
		function()
			return {
				{
					title = "Watch for config changes",
					fn = function()
						spoon.ConfigWatcher:toggle()
					end,
					checked = spoon.ConfigWatcher:isActive()
				},
				{
					title = "Mute on unknown networks",
					fn = function()
						local current = hs.settings.get("RBMuteSoundWhenJoiningUnknownNetworks")
						hs.settings.set("RBMuteSoundWhenJoiningUnknownNetworks", not current)
					end,
					checked = hs.settings.get("RBMuteSoundWhenJoiningUnknownNetworks")
				},
				{
					title = "Focused window highlighting",
					fn = function()
						hs.window.highlight.toggle()
					end
				},
				{title = "-"},
				{
					title = "Quit Hammerspoon",
					fn = function()
						hs.application("Hammerspoon"):kill()
					end
				}
			}
		end
	)

	return self
end

return obj
