local osascript = require("hs.osascript")

local obj = {}
obj.modal = nil

local _appObj = nil

local function searchNotesWithLaunchBar()
  osascript.applescript("tell app \"LaunchBar\" to perform action \"Notes: Search\"")
end

obj.actions = {
  searchNotesWithLaunchBar = {
    hotkey = {{"shift", "cmd"}, "o"},
    action = function()
      searchNotesWithLaunchBar()
    end,
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
