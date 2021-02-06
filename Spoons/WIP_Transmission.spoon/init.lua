local MenuBar = require("hs.menubar")
local Application = require("hs.application")
local FnUtils = require("hs.fnutils")
local Task = require("hs.task")
local Timer = require("hs.timer")

-- https://cli-ck.io/transmission-cli-user-guide/
-- https://github.com/transmission/transmission
-- https://github.com/transmission/transmission/wiki/Configuration-Files
-- https://github.com/transmission/transmission/wiki/Editing-Configuration-Files
-- defaults write org.m0k.transmission WarningDonate -bool false
-- defaults write org.m0k.transmission WarningLegal -bool false
-- defaults write org.m0k.transmission DownloadLocationConstant -bool false
-- defaults write org.m0k.transmission RatioCheck -bool true
-- defaults write org.m0k.transmission RatioLimit -float 1

-- transmission-remote -> torrent management
-- transmission-daemon -> server and config

local obj = {}
local statusItem = nil
local statusItemUpdateTimer = nil
local defaultTitle = "↑↓"

local function isRunning()
  local exitOK, _ = os.execute([[/usr/bin/pgrep -l transmission-daemon]])
  return exitOK
end

local function listTorrents()
  local task = Task.new("/usr/local/bin/transmission-remote", function(_, stdOut, _)
    local uploads = 0
    local downloads = 0
    local t = FnUtils.split(stdOut, "\n")
    table.remove(t, 1)
    table.remove(t, #t)
    for _, v in ipairs(t) do
      if string.match(v, " 100%% ") then
        uploads = uploads + 1
      else
        downloads = downloads + 1
      end
    end
    local title = defaultTitle
    if downloads > 0 then
      title = string.format("↓%s", downloads)
    end
    if uploads > 0 then
      title = string.format("↑%s", uploads)
    end
    if title then
      statusItem:setTitle(title)
    end
  end, {"-l"})
  task:start()
end

function obj:start()
  if not isRunning() then
    os.execute([[/usr/local/bin/transmission-daemon]])
  end
  if not statusItem then
    statusItem = MenuBar.new():setTitle(defaultTitle)
    statusItem:setMenu({
      {
        title = "Open Transmission Web",
        fn = function()
          os.execute([[/usr/bin/open http://localhost:9091/transmission/web/]])
        end,
      },
      {
        title = "Quit",
        fn = function()
          os.execute([[/usr/local/bin/transmission-remote --exit]])
        end,
      },
    })
  end
  if not statusItemUpdateTimer then
    statusItemUpdateTimer = Timer.doEvery(300, listTorrents)
  end
  statusItemUpdateTimer:start():fire()
  return self
end

function obj:stop()
  if statusItemUpdateTimer then
    statusItemUpdateTimer:stop()
    statusItemUpdateTimer = nil
  end
  os.execute([[/usr/bin/killall transmission-daemon]])
  if statusItem then
    statusItem:removeFromMenuBar()
    statusItem = nil
  end
  return self
end

function obj:init()
  -- if isRunning() then
  --   obj:start()
  -- end
  return self
end

return obj
