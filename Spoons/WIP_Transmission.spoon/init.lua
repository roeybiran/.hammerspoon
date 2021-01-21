local MenuBar = require("hs.menubar")
local Application = require("hs.application")

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

local function isRunning()
  local exitOK, _ = os.execute([[/usr/bin/pgrep -l transmission-daemon]])
  return exitOK
end

local function listTorrents() local arg = "-l" end

function obj:start()
  if not isRunning() then
    os.execute([[/usr/local/bin/transmission-daemon]])
  end
  if not statusItem then
    statusItem = MenuBar.new():setTitle("T")
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
  return self
end

function obj:stop()
  os.execute([[/usr/bin/killall transmission-daemon]])
  if statusItem then
    statusItem:removeFromMenuBar()
    statusItem = nil
  end
  return self
end

function obj:init()
  if isRunning() then
    obj:start()
  end
  return self
end

return obj
