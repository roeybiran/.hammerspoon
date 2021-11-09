local UI = require("rb.ui")

return function(appObj)
	local focusedWindow = appObj:focusedWindow()
	local focusedWindowTitle = (focusedWindow and focusedWindow:title()) or ""
	if string.match(focusedWindowTitle, "Bookmarks") then
		UI.getUIElement(appObj, {{"AXWindow", 1}, {"AXSplitGroup", 1}, {"AXTabGroup", 1}, {"AXGroup", 1}, {"AXButton", 1}}):performAction(
			"AXPress"
		)
		return
	end
	appObj:selectMenuItem({"File", "New Private Window"})
end
