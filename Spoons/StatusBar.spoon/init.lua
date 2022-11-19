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

local KEY = "RBDefaultBrowserBundleID"

local browsersBundleIDs = {"com.apple.Safari", "com.brave.Browser"}

local function installURLHandler()
	hs.urlevent.setDefaultHandler("http")
	hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
		local defaultBrowserID = hs.settings.get(KEY) or "com.apple.Safari"
		hs.urlevent.openURLWithBundle(fullURL, defaultBrowserID)
	end
end

function obj:start()
	installURLHandler()

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
					title = "Watch for appearance changes",
					fn = function()
						spoon.AppearanceWatcher:toggle()
					end,
					checked = spoon.AppearanceWatcher:isActive()
				},
				{
					title = "Mute on unknown networks",
					fn = function()
						spoon.WifiWatcher:toggle()
					end,
					checked = spoon.WifiWatcher:isActive()
				},
				{
					title = "Focused window highlighting",
					fn = function()
						hs.window.highlight.toggle()
					end
				},
				{title = "-"},
				{
					title = "Default Browser",
					menu = (function()
						local browsersMenuItems = {}
						for _, value in ipairs(browsersBundleIDs) do
							table.insert(
								browsersMenuItems,
								{
									title = hs.application.nameForBundleID(value),
									fn = function(_, _)
										hs.settings.set(KEY, value)
									end,
									image = hs.image.imageFromAppBundle(value),
									checked = hs.settings.get(KEY) == value
								}
							)
						end
						return browsersMenuItems
					end)()
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

	hs.urlevent.bind(
		"set-default-browser",
		function(_, params, _)
			if params and params.id then
				local newDefaultBrowserID = params.id
				local theApp = hs.application.get(newDefaultBrowserID)
				hs.notify.show("Default Browser Changed", (theApp and theApp:name()) or params.id, "")
				hs.settings.set(KEY, newDefaultBrowserID)
			else
				print("Unrecognized browser: " .. (params.id or "NULL"))
			end
		end
	)
	return self
end

return obj
