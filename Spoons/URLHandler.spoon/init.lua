local obj = {}

obj.__index = obj
obj.name = "URLHandler"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local DEFAULTS_KEY = "RBDefaultBrowserBundleID"
local browsersBundleIDs = {"com.apple.Safari", "com.brave.Browser", "company.thebrowser.Browser"}

function obj:start()
	if true then return end
	hs.urlevent.setDefaultHandler("http")

	hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
		local defaultBrowserID = hs.settings.get(DEFAULTS_KEY) or "com.apple.Safari"
		hs.urlevent.openURLWithBundle(fullURL, defaultBrowserID)
	end

	hs.urlevent.bind(
		"set-default-browser",
		function(_, params, _)
			if params and params.id then
				local newDefaultBrowserID = params.id
				local theApp = hs.application.get(newDefaultBrowserID)
				hs.notify.show("Default Browser Changed", (theApp and theApp:name()) or params.id, "")
				hs.settings.set(DEFAULTS_KEY, newDefaultBrowserID)
			else
				print("Unrecognized browser: " .. (params.id or "NULL"))
			end
		end
	)
end

function obj:generateMenuItem()
	local browsersMenuItems = {}
	for _, value in ipairs(browsersBundleIDs) do
		table.insert(
			browsersMenuItems,
			{
				title = hs.application.nameForBundleID(value),
				fn = function(_, _)
					hs.settings.set(DEFAULTS_KEY, value)
				end,
				image = hs.image.imageFromAppBundle(value),
				checked = hs.settings.get(DEFAULTS_KEY) == value
			}
		)
	end
	return browsersMenuItems
end

return obj
