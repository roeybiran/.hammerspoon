--- === DownloadsWatcher ===
---
--- Monitor the ~/Downloads folder, and execute a shell script that accepts newly downloaded files as arguments.
--- The script can be found in the Spoon's folder.
---
local PathWatcher = require("hs.pathwatcher")
local Task = require("hs.task")
local FS = require("hs.fs")
local Fnutils = require("hs.fnutils")
local Settings = require("hs.settings")
local Timer = require("hs.timer")
local Pasteboard = require("hs.pasteboard")
local spoon = spoon

local obj = {}

obj.__index = obj
obj.name = "DownloadsWatcher"
obj.version = "1.0"
obj.author = "roeybiran <roeybiran@icloud.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function tableCount(t)
  local n = 0
  for _, _ in pairs(t) do
    n = n + 1
  end
  return n
end

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local processedDownloadsInodesKey = "RBDownloadsWatcherProcessedDownloadsInodes"
local home = os.getenv("HOME")
local downloadsDir = home .. "/Downloads"
local shellScript = script_path() .. "/process_path.sh"
-- local supportedFormats = {"pdf", "zip", "tgz", "gz", "dmg", "heic", "webp"}
local filesToIgnore = {
  { pattern = ".DS_Store", isRegex =  false },
  { pattern = ".localized", isRegex = false },
  { pattern = ".", isRegex = false },
  { pattern = "..", isRegex = false },
  { pattern = "^.*%.crdownload$", isRegex = true },
  { pattern = "^.*%.download$", isRegex = true },
}
local processedDownloadsInodes
local pathWatcher
local throttledTimer

local function shellCallback(_, stdout, stderr)
  if string.match(stderr, "%s+") then
    print("DownloadsWatcher shell script stderr: ", stderr)
  end
  if string.match(stdout, "%s+") then
    print("DownloadWatcher shell script stdout: ", stdout)
  end
  if string.match(stdout, "/Downloads/") then
    -- Pasteboard.setContents(stdout)
  end
  spoon.StatusBar:removeTask()
end

local function shouldProcessFile(settings,  fileName)
  local shouldProcess = true
    for _, setting in ipairs(settings) do
      if setting.isRegex then
        if string.find(fileName, setting.pattern) then
          print("match", fileName, setting)
          shouldProcess = false
          break
        end
      else
        if fileName == setting.pattern then
          shouldProcess = false
          break
        end
      end
    end
    return  shouldProcess
end

local function watcherCallback()
  local iteratedFiles = {}
  local pathsToProcess = {}
  local iterFn, dirObj = FS.dir(downloadsDir)

  if not iterFn then
    print(string.format("DownloadsWatcher FS.dir enumerator error: %s", dirObj))
    return
  end

  for file in iterFn, dirObj do
    if shouldProcessFile(filesToIgnore, file) then
      local fullPath = downloadsDir .. "/" .. file
      local inode = FS.attributes(fullPath, "ino")
      if not Fnutils.contains(processedDownloadsInodes, inode) then
        table.insert(processedDownloadsInodes, inode)
        table.insert(pathsToProcess, fullPath)
      end
      table.insert(iteratedFiles, file)
    end
  end

  if tableCount(iteratedFiles) == 0 then
    print("DownloadsWatcher: ~/Downloads emptied, clearing inodes list")
    Settings.clear(processedDownloadsInodesKey)
    processedDownloadsInodes = {}
  else
    Settings.set(processedDownloadsInodesKey, processedDownloadsInodes)
  end

  -- process the files
  for _, path in ipairs(pathsToProcess) do
    spoon.StatusBar:addTask()
    Task.new(shellScript, shellCallback, {path}):start()
  end
end

--- DownloadsWatcher:stop()
---
--- Method
---
--- Stops the module.
---
function obj:stop()
  pathWatcher:stop()
  return self
end

--- DownloadsWatcher:start()
---
--- Method
---
--- Starts the module.
---
function obj:start()
  pathWatcher:start()
  return self
end

function obj:init()
  throttledTimer = Timer.delayed.new(1, watcherCallback)
  processedDownloadsInodes = Settings.get(processedDownloadsInodesKey) or {}
  pathWatcher = PathWatcher.new(downloadsDir, function()
    throttledTimer:start()
  end)
  return self
end

return obj
