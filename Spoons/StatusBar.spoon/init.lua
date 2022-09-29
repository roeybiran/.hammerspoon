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

obj.menuBarItem = nil
local spoonPath = script_path()
local iconPath = spoonPath .. "/statusicon.pdf"

local key = "RBDefaultBrowserBundleID"
local defaultBrowserID = hs.settings.get(key) or "com.apple.Safari"

local function installURLHandler()
	hs.urlevent.setDefaultHandler("http")
	hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
		hs.urlevent.openURLWithBundle(fullURL, defaultBrowserID)
	end
end

local bundles = {"com.apple.Safari", "com.brave.Browser"}
local browsers = {}
for _, value in ipairs(bundles) do
	table.insert(
		browsers,
		{
			title = hs.application.nameForBundleID(value),
			fn = function(_, _)
				defaultBrowserID = value
				hs.settings.set(key, value)
			end,
			image = hs.image.imageFromAppBundle(value),
			checked = defaultBrowserID == value
		}
	)
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
			title = "Focused window highlighting",
			fn = function()
				Window.highlight.toggle()
			end
		},
		{title = "-"},
		{
			title = "Default Browser",
			disabled = true
		},
		browsers[1],
		browsers[2],
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

	obj.menuBarItem = HSMenubar.new():setIcon(iconPath):setMenu(mainMenu)

	hs.urlevent.bind(
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
