--- === DownloadsWatcher ===
---
--- Monitor the ~/Downloads folder, and execute a shell script that accepts newly downloaded files as arguments.
local PathWatcher = require("hs.pathwatcher")
local FS = require("hs.fs")
local Settings = require("hs.settings")
local Timer = require("hs.timer")

local hs = hs
local spoon = spoon
local obj = {}

obj.name = "DownloadsWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.homepage = "https://github.com/roeybiran/.hammerspoon"

local processedDownloadsInodesKey = "RBDownloadsWatcherProcessedDownloadsInodes"
local _targetDir
local _rules
local processedDownloadsInodes
local pathWatcher
local throttledTimer

local function tableCount(t)
	local n = 0
	for _, _ in pairs(t) do
		n = n + 1
	end
	return n
end

-- return the displayName without the extension
local function getNameWithoutExtension(path)
	local splitted = hs.fnutils.split(path, ".", true)
	return table.unpack(splitted, 1, #splitted - 1)
end

-- https://codereview.stackexchange.com/a/90231
-- gets the extension INCLUDING leading dot
local function getExtension(path)
	return path:match("^.+(%..+)$")
end

local function shouldProcessWithFunction(path, rules)
	for _, rule in ipairs(rules) do
		for _, pattern in ipairs(rule.patterns) do
			if rule.isRegex then
				if path:lower():find(pattern:lower()) then
					return rule.fn
				end
			else
				if path:lower() == pattern:lower() then
					return rule.fn
				end
			end
		end
	end
end

local function watcherCallback(paths, flagTables)
	local iterFn, dirObj = FS.dir(_targetDir)
	local totalFiles = {}

	if not iterFn then
		hs.showError(string.format("DownloadsWatcher FS.dir enumerator error: %s", dirObj))
		return
	end

	local filesPendingProcessing = {}
	for fileNameAndExtension in iterFn, dirObj do
		local fnToExecute = shouldProcessWithFunction(fileNameAndExtension, _rules)
		if fnToExecute then
			local fullPath = _targetDir .. "/" .. fileNameAndExtension
			local nameWithoutExt = getNameWithoutExtension(fullPath)
			local ext = getExtension(fileNameAndExtension)
			local attrs = FS.attributes(fullPath)
			-- print(fileNameAndExtension, nameWithoutExt, attrs.inode, attrs.size, ext)
			if not hs.fnutils.contains(processedDownloadsInodes, attrs.ino) then
				table.insert(processedDownloadsInodes, attrs.ino)
				table.insert(filesPendingProcessing, {path = fullPath, exec = fnToExecute})
			end
			table.insert(totalFiles, fullPath)
		end
	end

	if tableCount(totalFiles) == 0 then
		print("DownloadsWatcher: ~/Downloads emptied, clearing inodes list")
		Settings.clear(processedDownloadsInodesKey)
		processedDownloadsInodes = {}
	else
		Settings.set(processedDownloadsInodesKey, processedDownloadsInodes)
	end

	-- process the files
	for _, fileObject in ipairs(filesPendingProcessing) do
		-- fileObject.exec(fileObject.path)
		print(fileObject.path, fileObject.fn)
	end
end

--- DownloadsWatcher:stop()
--- Method
--- Stops the module.
function obj:stop()
	pathWatcher:stop()
	return self
end

--- DownloadsWatcher:start()
--- Method
--- Starts the module.
---
--- Parameters:
---  * targetDir - string, default `~/Downloads`. The folder to monitor.
---  * rules - table, default `{}`. A list of rules to apply to the watcher. Each rule should have the following keys:
---    * patterns - a list of strings to match the file name's against.
---    * isRegex - whether to treat the strings in `patterns` as regular expressions.
---    * fn - the function to execute for a successful match. It should accept a single parameter - the full path to the matched file.
---
--- Returns:
---  * the module object.
function obj:start(rules, targetDir)
	_targetDir = targetDir or os.getenv("HOME") .. "/Downloads"
	_rules = rules or {}
	throttledTimer = throttledTimer or Timer.delayed.new(1, watcherCallback)
	processedDownloadsInodes = Settings.get(processedDownloadsInodesKey) or {}
	pathWatcher =
		pathWatcher or
		PathWatcher.new(
			_targetDir,
			function()
				throttledTimer:start()
			end
		):start()
	return self
end

return obj
