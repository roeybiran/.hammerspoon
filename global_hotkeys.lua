local hyper = {"shift", "cmd", "alt", "ctrl"}

local hotkeys = {
  keyboardLayoutManager = {toggleInputSource = {{}, 10}},
  globals = {focusMenuBar = {{"cmd", "shift"}, "1"}, rightClick = {hyper, "o"}, focusDock = {{"cmd", "alt"}, "d"}},
  windowManager = {
    pushLeft = {hyper, "left"},
    pushRight = {hyper, "right"},
    pushUp = {hyper, "up"},
    pushDown = {hyper, "down"},
    maximize = {hyper, "return"},
    center = {hyper, "c"},
  },
  notificationCenter = {
    firstButton = {hyper, "1"},
    secondButton = {hyper, "2"},
    thirdButton = {hyper, "3"},
    toggle = {hyper, "n"},
  },
}

return hotkeys
