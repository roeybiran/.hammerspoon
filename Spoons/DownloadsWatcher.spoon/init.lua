--- === DownloadsWatcher ===
---
--- Monitor the ~/Downloads folder, and execute a shell script that accepts newly downloaded files as arguments.
--- The script can be found in the Spoon's folder.
---
local PathWatcher = require("hs.pathwatcher")
local FS = require("hs.fs")
local FNUtils = require("hs.fnutils")
local Settings = require("hs.settings")
local Timer = require("hs.timer")
local Task = require("hs.task")

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
local trash = home .. "/.Trash/"

local function moveToTrash(path)
  local _displayName = FS.displayName(path)
  os.rename(path, trash .. _displayName)
end

local function stripExtension(path)
  local splitted = FNUtils.split(path, '.', true)
  return table.unpack(splitted, 1, #splitted - 1)
end

local function convertToJpg(path)
  local target = stripExtension(path) .. ".jpg"
  Task.new("/usr/bin/sips",
    function()
      moveToTrash(path)
    end,
    {"-s", "format", "jpeg", path, "--out", target}
  ):start()
end

local function renameJpegToJpg(path)
  local nameWithoutExt = stripExtension(path)
  os.rename(path, nameWithoutExt .. ".jpg")
end

local function handleZip(path)
  local nameWithoutExt = stripExtension(path)
  local newDir, err = FS.mkdir(nameWithoutExt)
  if not newDir then
    print(err)
    return
  end
  Task.new("/usr/bin/ditto", function()
    moveToTrash(path)
  end, {"-xk", path, nameWithoutExt})
    :start()
end

local rules = {
  {
    targetName = "bezeqint",
    tokens = {
      "בזק בינלאומי"
    }
  },
  {
    targetName = "payme",
    tokens = {
      "פאיימי"
    }
  },
  {
    targetName = "avrech",
    tokens = {
      "אברך-אלון"
    }
  },
  {
    targetName = "bezeq",
    tokens = {
      "בזק החברה הישראלית לתקשורת"
    }
  },
  {
    targetName = "apple music",
    tokens = {
      "Apple Music"
    }
  },
  {
    targetName = "apple icloud",
    tokens = {
      "iCloud:"
    }
  },
  {
    targetName = "icount",
    tokens = {
      "אייקאונט מערכות"
    }
  },
  {
    targetName = "google",
    tokens = {
      "Google Workspace"
    }
  },
  {
    targetName = "upress",
    tokens = {
      "upress"
    }
  },
  {
    targetName = "pango",
    tokens = {
      "פנגו"
    }
  },
  {
    targetName = "meshulam",
    tokens = {
      "משולם"
    }
  },
  {
    targetName = "facebook",
    tokens = {
      "Facebook"
    }
  },
}

local function renamePdfBasedOnText(path, text)
  local year
  local month
  for _, rule in ipairs(rules) do
    for _, token in ipairs(rule.tokens) do
      print(token)
    end
  end
end

local function handlePdf(path)
  local script = script_path() .. "/get_pdf_text.py"
  Task.new(script, function(exit, textResult, stderr)
    if exit ~= 0 then print(stderr) end
    renamePdfBasedOnText(path, textResult)
  end, { path })
    :start()
end

local function handleGz(path)
  Task.new("/usr/bin/tar",
    function(exit, out, err)
      print(exit, out, err)
      moveToTrash(path)
    end,
    {"-xvf", path, "-C", downloadsDir}
  ):start()
end

local function handleDmg(path)
  Task.new(script_path() .. "handle_dmg.sh",
    function (exit, out, err)
      print(exit, out, err)
    end,
    { path }
  ):start()
end

local rules = {
  {
    patterns = {".DS_Store", ".localized", ".", ".."},
    isRegex = false,
    exec = nil,
  },
  {
    patterns = {"%.crdownload$", "%.download$"},
    isRegex = true,
    exec = nil,
  },
  {
    patterns = {"%.ics$"},
    isRegex = true,
    exec = hs.open
  },
  {
    patterns = {"%.heic$", "%.webp$"},
    isRegex = true,
    exec = convertToJpg
  },
  {
    patterns = {"%.jpeg$"},
    isRegex = true,
    exec = renameJpegToJpg
  },
  {
    patterns = {"%.zip$"},
    isRegex = true,
    exec = handleZip
  },
  {
    patterns = {"%.pdf$"},
    isRegex = true,
    exec = handlePdf
  },
  {
    patterns = {"%.tgz$", "%.gz$"},
    isRegex = true,
    exec = handleGz
  },
  {
    patterns = {"%.dmg$"},
    isRegex = true,
    exec = handleDmg
  }
}

local processedDownloadsInodes
local pathWatcher
local throttledTimer

local function shouldProcessFile(_rules, fileName)
  local functionToExecute = nil
    for _, setting in ipairs(_rules) do
        for _, pattern in ipairs(setting.patterns) do
          if setting.isRegex then
            if string.find(string.lower(fileName), pattern) then
              functionToExecute = setting.exec
              break
            end
          else
            if fileName == setting.pattern then
              functionToExecute = setting.exec
              break
            end
          end
        end
    end
    return functionToExecute
end

local function watcherCallback()
  local iterFn, dirObj = FS.dir(downloadsDir)
  local totalFiles = {}
  local filesPendingProcessing = {}

  if not iterFn then
    print(string.format("DownloadsWatcher FS.dir enumerator error: %s", dirObj))
    return
  end

  for file in iterFn, dirObj do
    local functionToExecute = shouldProcessFile(rules, file)
    if functionToExecute then
      local fullPath = downloadsDir .. "/" .. file
      local inode = FS.attributes(fullPath, "ino")
      if not FNUtils.contains(processedDownloadsInodes, inode) then
        table.insert(processedDownloadsInodes, inode)
        table.insert(filesPendingProcessing, { path = fullPath, exec = functionToExecute })
      end
      table.insert(totalFiles, file)
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
  for _, file in ipairs(filesPendingProcessing) do
    file.exec(file.path)
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
