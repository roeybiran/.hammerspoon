local UI = require("util.ax")
local Util = require("util.util")

return function(appObj)
	local firstColumn =
		UI.getUIElement(
		appObj,
		{
			{"AXWindow", 1},
			{"AXSplitGroup", 1},
			{"AXTabGroup", 1},
			{"AXGroup", 1},
			{"AXScrollArea", 1},
			{"AXOutline", 1},
			{"AXGroup", 1},
			{"AXButton", "AXTitle", "Website"}
		}
	)
	if not firstColumn then
		print("Safari.rightSizeBookmarksOrHistoryColumn: couldn't find the first column")
		return
	end
	local frame = firstColumn:attributeValue("AXFrame")
	local x = frame.x + frame.w
	local y = frame.y + 5
	Util.doubleLeftClick({x, y})
end
