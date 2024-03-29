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
			rect = Geometry.rect({minX, minY, midX, midY}),
			onLeft = "west",
			onRight = "northEast",
			onUp = "north",
			onDown = "southWest"
		},
		northEast = {
			rect = Geometry.rect({midX, minY, midX, midY}),
			onLeft = "northWest",
			onRight = "east",
			onUp = "north",
			onDown = "southEast"
		},
		southWest = {
			rect = Geometry.rect({minX, midY, midX, midY + menuBarHeight}),
			onLeft = "west",
			onRight = "southEast",
			onUp = "northWest",
			onDown = "south"
		},
		southEast = {
			rect = Geometry.rect({midX, midY, midX, midY + menuBarHeight}),
			onLeft = "southWest",
			onRight = "east",
			onUp = "northEast",
			onDown = "south"
		},
		west = {
			rect = Geometry.rect({minX, minY, midX, maxY}),
			onLeft = "fullScreen",
			onRight = "east",
			onUp = "northWest",
			onDown = "southWest"
		},
		east = {
			rect = Geometry.rect({midX, minY, midX, maxY}),
			onLeft = "west",
			onRight = "fullScreen",
			onUp = "northEast",
			onDown = "southEast"
		},
		south = {
			rect = Geometry.rect({minX, midY, maxX, midY + menuBarHeight}),
			onLeft = "southWest",
			onRight = "southEast",
			onUp = "north",
			onDown = "fullScreen"
		},
		north = {
			rect = Geometry.rect({minX, minY, maxX, midY}),
			onLeft = "northWest",
			onRight = "northEast",
			onUp = "fullScreen",
			onDown = "south"
		},
		fullScreen = {
			rect = Geometry.rect({minX, minY, maxX, maxY}),
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
local fallbacks = {Up = "north", Down = "south", Right = "east", Left = "west"}

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
	local frontWindow = Window.frontmostWindow()
	local frontWindowFrame = frontWindow:frame()
	if frontWindowFrame:equals(possibleCells.fullScreen.rect) then
		frontWindow:setFrame(possibleCells.northWest.rect)
		frontWindow:centerOnScreen()
	else
		frontWindow:setFrame(possibleCells.fullScreen.rect)
	end
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
		maximize = function()
			maximize()
		end,
		pushLeft = function()
			pushToCell("Left")
		end,
		pushRight = function()
			pushToCell("Right")
		end,
		pushDown = function()
			pushToCell("Down")
		end,
		pushUp = function()
			pushToCell("Up")
		end,
		center = function()
			Window.frontmostWindow():centerOnScreen()
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

return obj
