--- === StatusBar ===
---
--- Enables a status menu item with the familiar Hammerspoon logo, but with customizable contents and a flashing mode to signal ongoing operations.
local Application = require("hs.application")
local HSMenubar = require("hs.menubar")
local Window = require("hs.window")
local FNUtils = require("hs.fnutils")
local spoon = spoon
local hs = hs

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

local menuBarItem
local spoonPath = script_path()
local iconPath = spoonPath .. "/statusicon.pdf"
local browsers = {
	"com.apple.Safari",
	"com.brave.Browser"
}
local defaultBrowserID = "com.apple.Safari"

local URLEvent = require("hs.urlevent")
local Image = require("hs.image")
local function installURLHandler()
	URLEvent.setDefaultHandler("http")
	URLEvent.httpCallback = function(scheme, host, params, fullURL, senderPID)
		URLEvent.openURLWithBundle(fullURL, defaultBrowserID)
	end
end

local function mainMenu()
	return {
		{
			title = "General Settings",
			disabled = true
		},
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
			title = "Window highlighting",
			fn = function()
				Window.highlight.toggle()
			end
		},
		{title = "-"},
		{
			title = "Default Browser",
			disabled = true
		},
		{
			title = "Safari",
			fn = function(_, _)
				defaultBrowserID = "com.apple.Safari"
			end,
			image = Image.imageFromAppBundle("com.apple.Safari"),
			checked = defaultBrowserID == "com.apple.Safari"
		},
		{
			title = "Brave",
			fn = function(_, _)
				defaultBrowserID = "com.brave.Browser"
			end,
			image = Image.imageFromAppBundle("com.brave.Browser"),
			checked = defaultBrowserID == "com.brave.Browser"
		},
		{title = "-"},
		{
			title = "Quit Hammerspoon",
			fn = function()
				Application("Hammerspoon"):kill()
			end
		}
	}
end

function obj:start()
	installURLHandler()
	menuBarItem = HSMenubar.new():setIcon(iconPath):setMenu(mainMenu)
	URLEvent.bind(
		"set-default-browser",
		function(eventName, params, _)
			if params and params.id and FNUtils.contains(browsers, params.id) then
				defaultBrowserID = params.id
				local theApp = Application.get(defaultBrowserID)
				hs.notify.show("Default Browser Changed", (theApp and theApp:name()) or params.id, "")
			else
				hs.showError("Unrecognized browser: " .. (params.id or "NULL"))
			end
		end
	)
	return self
end

return obj
