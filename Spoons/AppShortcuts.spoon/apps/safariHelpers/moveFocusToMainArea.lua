local UI = require("rb.ui")

return function(appObj, includeSidebar)
	-- ui scripting notes:
	-- when the status bar overlay shows, it's the first window. you should look for the "Main" window instead.
	-- "pane1" = is either the main web area, or the sidebar

	-- Safari 14 welcome page
	local UIElementHomeScreenView = {
		{"AXWindow", "AXRoleDescription", "standard window"},
		{"AXSplitGroup", 1},
		{"AXTabGroup", 1},
		{"AXScrollArea", 1}
	}
	if UI.getUIElement(appObj, UIElementHomeScreenView) then
		return
	end

	local sidebar = {
		{"AXWindow", "AXRoleDescription", "standard window"},
		{"AXSplitGroup", 1},
		{"AXGroup", 1},
		{"AXScrollArea", 1},
		{"AXOutline", 1}
	}
	local bookmarksAndHistoryView = {
		{"AXWindow", "AXRoleDescription", "standard window"},
		{"AXSplitGroup", 1},
		{"AXTabGroup", 1},
		{"AXGroup", 1},
		{"AXScrollArea", 1},
		{"AXOutline", 1}
	}
	local standardWebpageView = {
		{"AXWindow", "AXRoleDescription", "standard window"},
		{"AXSplitGroup", 1},
		{"AXTabGroup", 1},
		{"AXGroup", 1},
		{"AXGroup", 1},
		{"AXScrollArea", 1},
		{"AXWebArea", 1}
	}
	local targetPane
	local sideBar
	local webArea = UI.getUIElement(appObj, standardWebpageView)
	local bookmarksOrHistory = UI.getUIElement(appObj, bookmarksAndHistoryView)
	if includeSidebar then
		sideBar = UI.getUIElement(appObj, sidebar)
	end
	if sideBar then
		targetPane = sideBar
	elseif webArea then
		targetPane = webArea
	elseif bookmarksOrHistory then
		targetPane = bookmarksOrHistory
	end

	if targetPane then
		targetPane:setAttributeValue("AXFocused", true)
	end
end
