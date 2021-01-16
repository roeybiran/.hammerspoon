--- === spoon name ===
---
--- description...
local Window = require("hs.window")

local obj = {}

obj.__index = obj
obj.name = "AppHighlighter"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:start()
  -- Window.highlight.start()
end

function obj:stop() end

function obj:init() end

return obj

-- print(newBundleID)
-- if event == Application.watcher.activated then
-- local Canvas = require("hs.canvas")
-- local canvas = Canvas.new(hs.screen.mainScreen():frame())
-- canvas:level(hs.canvas.windowLevels.floating)
-- hs.window.highlight.ui.flashDuration = 0.3
-- hs.window.highlight.ui.overlay = true
-- local focusedWindow = appObj:focusedWindow():frame()
-- canvas[1] = {
--   type = "rectangle",
--   action = "stroke",
--   strokeColor = {red = 1},
--   strokeWidth = 3,
--   roundedRectRadii = {xRadius = 5, yRadius = 5}
-- }
-- canvas:frame(focusedWindow)
-- canvas:show()
