local AppleScript = require("hs.osascript").applescript

return function()
	-- AppleScript method
	local _, currentURL, _ = AppleScript 'tell application "Safari" to tell window 1 to return URL of current tab'
	if not currentURL then
		return
	end
	currentURL = currentURL:gsub("^.+://", "")
	local lastSlash = currentURL:find("/")
	if lastSlash then
		currentURL = currentURL:sub(1, lastSlash - 1)
	end
	return currentURL
end
