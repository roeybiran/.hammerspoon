local EventTap = require("hs.eventtap")
local AX = require("hs.axuielement")

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

return function(appObj, modal)
	-- moves focus to the bookmarks/history list
	local title = appObj:focusedWindow():title()
	-- if we're in the history or bookmarks windows
	if title:match("Bookmarks") or title:match("History") then
		local axApp = AX.applicationElement(appObj)
		-- if search field is focused
		if axApp:attributeValue("AXFocusedUIElement"):attributeValue("AXSubrole") == "AXSearchField" then
			dofile(script_path() .. "/moveFocusToMainArea.lua")(appObj, false)
			return
		end
	end
	modal:exit()
	EventTap.keyStroke({}, "tab")
	modal:enter()
end
