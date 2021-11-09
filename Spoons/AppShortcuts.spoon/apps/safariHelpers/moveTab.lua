local AppleScript = require("hs.osascript").applescript

return function(direction)
	local args
	if direction == "right" then
		args = {"+", "1", "before", "after"}
	else
		args = {"-", "(index of last tab)", "after", "before"}
	end
	local script =
		[[
  tell application "Safari"
    tell window 1
      set sourceIndex to index of current tab
      set targetIndex to (sourceIndex %s 1)
      if not (exists tab targetIndex) then
        set targetIndex to %s
        move tab sourceIndex to %s tab targetIndex
      end if
      move tab sourceIndex to %s tab targetIndex
      set current tab to tab targetIndex
    end tell
  end tell
]]
	script = string.format(script, table.unpack(args))
	AppleScript(script)
end
