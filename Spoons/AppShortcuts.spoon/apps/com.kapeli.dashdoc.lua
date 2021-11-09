local obj = {}
local _appObj = nil

local function clickOnHistoryMenuItem(appObj)
	appObj:selectMenuItem({"History"})
end

local function toggleBookmarks(appObj)
	if appObj:selectMenuItem({"Bookmarks", "Show Bookmarks..."}) then
		return
	end
	appObj:selectMenuItem({"Bookmarks", "Hide Bookmarks"})
end

obj.modal = nil

obj.actions = {
	clickOnHistoryMenuItem = {
		hotkey = {"cmd", "y"},
		action = function()
			clickOnHistoryMenuItem(_appObj)
		end
	},
	toggleBookmarks = {
		hotkey = {{"cmd", "alt"}, "b"},
		action = function()
			toggleBookmarks(_appObj)
		end
	}
}

function obj:start(appObj)
	_appObj = appObj
	obj.modal:enter()
	return self
end

function obj:stop()
	obj.modal:exit()
	return self
end

return obj
