local AppleScript = require("hs.osascript").applescript

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

return function(direction)
	local jsFile = script_path() .. "/navigatePages.js"
	local script =
		[[
  set _arg to "%s"
  set theFile to (POSIX file "%s" as alias)
  set theScript to read theFile as string
  set theScript to "var direction = '" & _arg & "'; " & theScript
  tell application "Safari"
    tell (window 1 whose visible of it = true)
      tell (tab 1 whose visible of it = true)
        return do JavaScript theScript
      end tell
    end tell
  end tell
]]
	script = string.format(script, direction, jsFile)
	AppleScript(script)
end
