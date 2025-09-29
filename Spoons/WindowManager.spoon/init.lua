--- === WindowManager ===
---
--- Moves and resizes windows.
--- Features:
---   * Every window can be resized to be a quarter, half or the whole of the screen.
---   * Every window can be positioned anywhere on the screen, WITHIN the constraints of a grid. The grids are 1x1, 2x2 and 4x4 for maximized, half-sized and quarter-sized windows, respectively.
---   * Any given window can be cycled through all sizes and locations with just 4 keys. For example: northwest quarter → northeast quarter → right half ↓ southeast quarter ↓ bottom half ↓ full-screen.
local Window = require("hs.window")
local Screen = require("hs.screen")
local Geometry = require("hs.geometry")
local Spoons = require("hs.spoons")

local obj = {}

obj.__index = obj
obj.name = "WindowManager"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function calculatePossibleCells()
	local mainScreen = Screen.mainScreen()
	local usableFrame = mainScreen:frame()
	local menuBarHeight = mainScreen:fullFrame().h - usableFrame.h
	local minX = 0
	local midX = usableFrame.w / 2
	local maxX = usableFrame.w
	local minY = usableFrame.y -- not a simple zero because of the menu bar
	local midY = usableFrame.h / 2
	local maxY = usableFrame.h

	local possibleCells = {
		northWest = {
			rect = Geometry.rect({ minX, minY, midX, midY }),
			onLeft = "west",
			onRight = "northEast",
			onUp = "north",
			onDown = "southWest"
		},
		northEast = {
			rect = Geometry.rect({ midX, minY, midX, midY }),
			onLeft = "northWest",
			onRight = "east",
			onUp = "north",
			onDown = "southEast"
		},
		southWest = {
			rect = Geometry.rect({ minX, midY, midX, midY + menuBarHeight }),
			onLeft = "west",
			onRight = "southEast",
			onUp = "northWest",
			onDown = "south"
		},
		southEast = {
			rect = Geometry.rect({ midX, midY, midX, midY + menuBarHeight }),
			onLeft = "southWest",
			onRight = "east",
			onUp = "northEast",
			onDown = "south"
		},
		west = {
			rect = Geometry.rect({ minX, minY, midX, maxY }),
			onLeft = "fullScreen",
			onRight = "east",
			onUp = "northWest",
			onDown = "southWest"
		},
		east = {
			rect = Geometry.rect({ midX, minY, midX, maxY }),
			onLeft = "west",
			onRight = "fullScreen",
			onUp = "northEast",
			onDown = "southEast"
		},
		south = {
			rect = Geometry.rect({ minX, midY, maxX, midY + menuBarHeight }),
			onLeft = "southWest",
			onRight = "southEast",
			onUp = "north",
			onDown = "fullScreen"
		},
		north = {
			rect = Geometry.rect({ minX, minY, maxX, midY }),
			onLeft = "northWest",
			onRight = "northEast",
			onUp = "fullScreen",
			onDown = "south"
		},
		fullScreen = {
			rect = Geometry.rect({ minX, minY, maxX, maxY }),
			onLeft = "west",
			onRight = "east",
			onUp = "north",
			onDown = "south"
		}
	}

	return possibleCells
end

local possibleCells
local watcher
local fallbacks = { Up = "north", Down = "south", Right = "east", Left = "west" }

local function pushToCell(direction)
	local frontWindow = Window.frontmostWindow()
	local frontWindowFrame = frontWindow:frame()
	for _, cellProperties in pairs(possibleCells) do
		if frontWindowFrame:equals(cellProperties.rect) then
			local targetCellName = cellProperties["on" .. direction]
			local targetCell = possibleCells[targetCellName].rect
			frontWindow:setFrame(targetCell)
			return
		end
	end
	local targetCellName = fallbacks[direction]
	frontWindow:setFrame(possibleCells[targetCellName].rect)
end

local function maximize()
	-- local frontWindow = Window.frontmostWindow()
	-- local frontWindowFrame = frontWindow:frame()
	-- if frontWindowFrame:equals(possibleCells.fullScreen.rect) then
	-- 	frontWindow:setFrame(possibleCells.northWest.rect)
	-- 	frontWindow:centerOnScreen()
	-- else
	-- 	frontWindow:setFrame(possibleCells.fullScreen.rect)
	-- end
	-- Window.frontmostWindow():setFrame(possibleCells.fullScreen.rect)

	local result = hs.application.frontmostApplication():selectMenuItem("Fill")
	if result then
		return
	end
	Window.frontmostWindow():setFrame(possibleCells.fullScreen.rect)
end

function obj:pushLeft()
	pushToCell("Left")
end

function obj:pushRight()
	pushToCell("Right")
end

function obj:pushDown()
	pushToCell("Down")
end

function obj:pushUp()
	pushToCell("Up")
end

function obj:center()
	if hs.application.frontmostApplication():selectMenuItem("Center") then
		return
	end
	Window.frontmostWindow():centerOnScreen()
end

function obj:maximize()
	maximize();
end

--- WindowManager:bindHotKeys(_mapping)
--- Method
--- This module offers the following functionalities:
---   * `maximize` - maximizes the frontmost window. If it's already maximized, it will be centered and resized to be a quarter of the screen.
---   * `pushLeft` - moves and/or resizes a window towards the left of the screen.
---   * `pushRight` - moves and/or resizes a window towards the right of the screen.
---   * `pushDown` - moves and/or resizes a window towards the bottom of the screen.
---   * `pushUp` - moves and/or resizes a window towards the top of the screen.
---   * `pushLeft` - moves and/or resizes a window towards the left of the screen.
---   * `center` - centers the frontmost window.
--- Parameters:
---   * `_mapping` - A table that conforms to the structure described in the Spoon plugin documentation.
function obj:bindHotKeys(_mapping)
	local def = {
		pushLeft = function()
			obj:pushLeft();
		end,
		pushRight = function()
			obj:pushRight();
		end,
		pushDown = function()
			obj:pushDown();
		end,
		pushUp = function()
			obj:pushUp();
		end,
		center = function()
			obj:center()
		end,
		maximize = function()
			obj:maximize();
		end
	}
	Spoons.bindHotkeysToSpec(def, _mapping)
	return self
end

function obj:init()
	watcher =
		Screen.watcher.new(
			function()
				possibleCells = calculatePossibleCells()
			end
		)
	return self
end

function obj:start()
	possibleCells = calculatePossibleCells()
	watcher:start()
	return self
end

--  Enables modal hotkeys that allow for more granular control over the size and position of the frontmost window. Shows a small window that serves as a cheat sheet.
function _()
	local Window = require("hs.window")
	local Geometry = require("hs.geometry")
	local Hotkey = require("hs.hotkey")
	local Screen = require("hs.screen")
	local Drawing = require("hs.drawing")
	local Webview = require("hs.webview")

	local obj = {}

	obj.__index = obj
	obj.name = "WindowManagerModal"
	obj.version = "1.0"
	obj.author = "roeybiran <roeybiran@icloud.com>"
	obj.homepage = "https://github.com/Hammerspoon/Spoons"
	obj.license = "MIT - https://opensource.org/licenses/MIT"

	obj.windowManagerModal = nil
	obj.cheatSheet = nil

	local function move(direction)
		local point
		if direction == "right" then
			point = { 60, 0 }
		elseif direction == "left" then
			point = { -60, 0 }
		elseif direction == "up" then
			point = { 0, -60 }
		elseif direction == "down" then
			point = { 0, 60 }
		end
		Window.focusedWindow():move(point)
	end

	local function resize(resizeKind)
		local rect
		local currentFrame = Window.focusedWindow():frame()
		local x = currentFrame._x
		local y = currentFrame._y
		local w = currentFrame._w
		local h = currentFrame._h
		if resizeKind == "growToTop" then
			rect = { x = x, y = y - 30, w = w, h = h + 30 }
		elseif resizeKind == "growToRight" then
			rect = { x = x, y = y, w = w + 30, h = h }
		elseif resizeKind == "growToBottom" then
			rect = { x = x, y = y, w = w, h = h + 30 }
		elseif resizeKind == "growToLeft" then
			rect = { x = x - 30, y = y, w = w + 30, h = h }
		elseif resizeKind == "shrinkFromTop" then
			rect = { x = x, y = y + 30, w = w, h = h - 30 }
		elseif resizeKind == "shrinkFromBottom" then
			rect = { x = x, y = y, w = w, h = h - 30 }
		elseif resizeKind == "shrinkFromRight" then
			rect = { x = x, y = y, w = w - 30, h = h }
		elseif resizeKind == "shrinkFromLeft" then
			rect = { x = x + 30, y = y, w = w - 30, h = h }
		end
		Window.focusedWindow():setFrame(Geometry.rect(rect))
	end

	local modalHotkeys = {
		{ shortcut = { modifiers = {}, key = "up" },    pressedfn = move, repeatfn = move, arg = "up",    txt = "Move Up" },
		{ shortcut = { modifiers = {}, key = "down" },  pressedfn = move, repeatfn = move, arg = "down",  txt = "Move Down" },
		{ shortcut = { modifiers = {}, key = "left" },  pressedfn = move, repeatfn = move, arg = "left",  txt = "Move Left" },
		{ shortcut = { modifiers = {}, key = "right" }, pressedfn = move, repeatfn = move, arg = "right", txt = "Move Right" },
		{
			shortcut = { modifiers = { "alt" }, key = "left" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "shrinkFromRight",
			txt = "Shrink from Right"
		},
		{
			shortcut = { modifiers = { "alt" }, key = "right" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "shrinkFromLeft",
			txt = "Shrink from Left"
		},
		{
			shortcut = { modifiers = { "alt" }, key = "up" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "shrinkFromBottom",
			txt = "Shrink from Bottom"
		},
		{
			shortcut = { modifiers = { "alt" }, key = "down" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "shrinkFromTop",
			txt = "Shrink from Top"
		},
		{
			shortcut = { modifiers = { "cmd" }, key = "right" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "growToRight",
			txt = "Grow to Right"
		},
		{
			shortcut = { modifiers = { "cmd" }, key = "left" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "growToLeft",
			txt = "Grow to Left"
		},
		{
			shortcut = { modifiers = { "cmd" }, key = "down" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "growToBottom",
			txt = "Grow to Bottom"
		},
		{
			shortcut = { modifiers = { "cmd" }, key = "up" },
			pressedfn = resize,
			repeatfn = resize,
			arg = "growToTop",
			txt = "Grow to Top"
		}
	}

	local glyps = { alt = "⌥", ctrl = "⌃", cmd = "⌘", left = "←", right = "→", down = "↓", up = "↑" }

	local function createCheatSheet()
		local cheatSheetContents = ""
		-- build the cheatsheet
		for _, keyDescription in ipairs(modalHotkeys) do
			local shortcut = keyDescription.shortcut
			local shortcutString = ""
			for _, modifier in ipairs(shortcut.modifiers) do
				shortcutString = shortcutString .. glyps[modifier]
			end
			shortcutString = shortcutString .. glyps[shortcut.key]
			local action = keyDescription.txt
			local row =
				string.format(
					[[
        <tr>
            <td class="glyphs">%s</td>
            <td class="description">%s</td>
        </tr>
    ]],
					shortcutString,
					action
				)
			cheatSheetContents = cheatSheetContents .. "\n" .. row
		end
		-- format the html
		local html =
			string.format(
				[[
  <!DOCTYPE html>
  <html>
    <head>
    <style type="text/css">
      html, body {
        background-color: black;
        color: white;
        font-family: -apple-system, sans-serif;
        font-size: 12px;
      }
      td {
      }
      table {
        padding-top: 24px;
        padding-bottom: 24px;
        padding-left: 24px;
        padding-right: 24px;
      }
      .glyphs {
        text-align: left;
        padding-right: 16px;
        font-weight: bolder;
      }
      .description {
        text-align: right;
        padding-left: 16px;
      }
    </style>
    </head>
    <body>
      <table>%s</table>
    </body>
  </html>
  ]],
				cheatSheetContents
			)
		-- window settings
		local screenFrame = Screen.mainScreen():frame()
		local screenCenterX = screenFrame.w / 2
		local screenCenterY = screenFrame.h / 2
		local modalWidth = screenFrame.w / 7
		local modalHeight = screenFrame.h / 3
		obj.cheatSheet =
			Webview.new(
				{
					x = (screenCenterX - modalWidth / 2),
					y = (screenCenterY - modalHeight / 2),
					w = modalWidth,
					h = modalHeight
				}
			)
		obj.cheatSheet:windowStyle({ "titled", "nonactivating", "utility" })
		obj.cheatSheet:shadow(true)
		obj.cheatSheet:windowTitle("Window Manager")
		obj.cheatSheet:html(html)
		obj.cheatSheet:level(Drawing.windowLevels._MaximumWindowLevelKey)
	end

	function obj:start()
		obj.windowManagerModal:enter()
		createCheatSheet()
		obj.cheatSheet:show()
	end

	function obj:stop()
		obj.windowManagerModal:exit()
		obj.cheatSheet:delete()
	end

	function obj:init()
		obj.windowManagerModal = Hotkey.modal.new()
		for _, binding in ipairs(modalHotkeys) do
			local arg = binding.arg
			obj.windowManagerModal:bind(
				binding.shortcut.modifiers,
				binding.shortcut.key,
				function()
					binding.pressedfn(arg)
				end,
				nil,
				function()
					binding.repeatfn(arg)
				end
			)
		end
		obj.windowManagerModal:bind({}, "escape", obj.stop)
		obj.windowManagerModal:bind({}, "return", obj.stop)
		obj.windowManagerModal:bind({ "cmd", "alt", "ctrl", "shift" }, "w", obj.stop)
	end

	return obj
end

return obj
