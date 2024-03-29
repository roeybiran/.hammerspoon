local KeyCodes = require("hs.keycodes")
local FnUtils = require("hs.fnutils")
local AX = require("hs.axuielement")
local Settings = require("hs.settings")
local Observer = AX.observer
local hs = hs

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

local obj = {}
local _appObj
local observer

local layoutsPerURLKey = "RBSafariLayoutsForURL"
local inputSourceSwitchExcludedUrls = {"bookmarks://", "history://", "favorites://", nil, ""}
local prevUrl
local defaultLayout = "ABC"

local helpers = script_path() .. "/safariHelpers/"
local getCurrentURL = dofile(helpers .. "getCurrentURL.lua")
local moveFocusToMainArea = dofile(helpers .. "moveFocusToMainArea.lua")
local isAddressBarFocused = dofile(helpers .. "isAddressBarFocused.lua")
local rightSizeBookmarksOrHistoryColumn = dofile(helpers .. "rightSizeBookmarksOrHistoryColumn.lua")
local newBookmarksFolder = dofile(helpers .. "newBookmarksFolder.lua")
local performPageNavigation = dofile(helpers .. "performPageNavigation.lua")
local focusFirstSearchResult = dofile(helpers .. "focusFirstSearchResult.lua")
local switchLayoutOnAdressBarFocus = dofile(helpers .. "switchLayoutOnAdressBarFocus.lua")
local moveTab = dofile(helpers .. "moveTab.lua")

local function observerCallback(observerObj, uiElement, notifName, moreInfo)
	if notifName == "AXFocusedUIElementChanged" then
		switchLayoutOnAdressBarFocus(uiElement, "ABC")
	end

	if notifName == "AXTitleChanged" then
		local currentSettings = Settings.get(layoutsPerURLKey) or {}
		local currentLayout = KeyCodes.currentLayout()
		if prevUrl then
			if currentLayout == defaultLayout then
				currentSettings[prevUrl] = nil
			else
				currentSettings[prevUrl] = currentLayout
			end
		end

		local currentUrl = getCurrentURL()
		prevUrl = currentUrl

		-- print(hs.inspect(currentSettings), prevUrl)

		local newLayout = currentSettings[currentUrl]
		if not newLayout or FnUtils.contains(inputSourceSwitchExcludedUrls, currentUrl) then
			newLayout = "ABC"
		end
		KeyCodes.setLayout(newLayout)
		Settings.set(layoutsPerURLKey, currentSettings)
	end

	if notifName == "_AXLoadComplete" then
		if not getCurrentURL():lower():match("google") then
			return
		end
		-- unfocuses the address bar (if focused) after loading a web page.
		-- Useful when using Vimari's hints feature, which don't work with the address bar focused.
		-- in my experience, the address bar remains focused only after searching in Google
		local isFocused = isAddressBarFocused(_appObj)
		if not isFocused then
			return
		end
		moveFocusToMainArea(_appObj, true)
	end
end

local function setupObserver(appObj)
	local pid = appObj:pid()
	observer = Observer.new(pid)
	local element = AX.applicationElement(appObj)
	-- if Safari has just been launched, this may return "*accessibility error* (0x60000104cbf8)"
	-- this value is not nil so we need to check by casting
	if not element:isValid() then
		return
	end
	observer:addWatcher(element, "AXTitleChanged"):addWatcher(element, "AXFocusedUIElementChanged"):addWatcher(
		element,
		"AXLoadComplete"
	):callback(observerCallback):start()
end

obj.modal = nil

obj.actions = {
	--- moveTabLeft - moves the focused tab one position to the left.
	moveTabLeft = {
		action = function()
			moveTab("left")
		end,
		hotkey = {"ctrl", ","}
	},
	--- moveTabRight - moves the focused tab one position to the right.
	moveTabRight = {
		action = function()
			moveTab("right")
		end,
		hotkey = {"ctrl", "."}
	},
	--- newWindow - ensures a new window will be opened rather than a tab. Useful when the "Prefer tabs" setting in the Dock Preference Pane is set to "always".
	newWindow = {
		action = function()
			_appObj:selectMenuItem({"File", "New Window"})
		end,
		hotkey = {"cmd", "n"}
	},
	--- goToNextPage - navigates to a web page's next page, if applicable.
	goToNextPage = {
		action = function()
			performPageNavigation("next")
		end,
		hotkey = {"ctrl", "n"}
	},
	--- goToPreviousPage - navigates to a web page's previous page, if applicable.
	goToPreviousPage = {
		action = function()
			performPageNavigation("previous")
		end,
		hotkey = {"ctrl", "p"}
	},
	--- newBookmarksFolder - creates a new bookmarks folder. Works only while viewing bookmarks.
	newBookmarksFolder = {
		action = function()
			newBookmarksFolder(_appObj)
		end,
		hotkey = {{"cmd", "shift"}, "n"}
	},
	--- rightSizeBookmarksOrHistoryColumn - sizes to fit the first column of the bookmarks/history view.
	rightSizeBookmarksOrHistoryColumn = {
		action = function()
			rightSizeBookmarksOrHistoryColumn(_appObj)
		end,
		hotkey = {"alt", "r"}
	},
	--- firstSearchResult - in a history/bookmarks view and when the search field is focused, moves focus the 1st search result.
	firstSearchResult = {
		action = function()
			focusFirstSearchResult(_appObj, obj.modal)
		end,
		hotkey = {{}, "tab"}
	}
}

function obj:start(appObj)
	_appObj = appObj
	obj.modal:enter()

	setupObserver(appObj)
	-- manually trigger once on app activation to switch to the proper layout
	observerCallback(nil, nil, "AXTitleChanged", nil)
	return self
end

function obj:stop()
	if observer then
		observer:stop()
		observer = nil
	end
	obj.modal:exit()
	return self
end

return obj
