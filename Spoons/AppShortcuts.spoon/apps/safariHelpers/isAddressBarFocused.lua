local UI = require("rb.ui")
local AX = require("hs.axuielement")

return function(appObj)
	local axAppObj = AX.applicationElement(appObj)
	local addressBarObject = UI.getUIElement(axAppObj, {{"AXWindow", "AXMain", true}, {"AXToolbar", 1}})
	local addressBarChildren = (addressBarObject and addressBarObject:attributeValue("AXChildren")) or {}
	for _, toolbarObject in ipairs(addressBarChildren) do
		local toolbarObjectsChilds = toolbarObject:attributeValue("AXChildren")
		if toolbarObjectsChilds then
			for _, toolbarObjectChild in ipairs(toolbarObjectsChilds) do
				if toolbarObjectChild:attributeValue("AXRole") == "AXTextField" then
					return toolbarObjectChild:attributeValue("AXFocused")
				end
			end
		end
	end
end
