-- switches to ABC upon focusing the address bar
local KeyCodes = require("hs.keycodes")

return function(uiElement, layout)
	if KeyCodes.currentLayout() == layout then
		return
	end
	local path = uiElement and uiElement:path()
	local app = path and path[1]
	local focusedElement = app and app:attributeValue("AXFocusedUIElement")
	local identifier = focusedElement and focusedElement:attributeValue("AXIdentifier")
	if identifier == "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD" then
		KeyCodes.setLayout(layout)
	end
end
