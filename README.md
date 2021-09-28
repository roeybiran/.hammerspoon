# .hammerspoon

Personal [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) config.

## Features

- Documented, modular and completely Spoon-based.
- Includes, among others: a `~/Downloads` watcher, Wi-Fi watcher, and an extensible app watcher with lots of app-specific automations.
- Easy on system resources.

## Notes

- Requires Hammerspoon v0.9.79 or newer.
- The `rb` folder included with this repo contains dependencies for some Spoons. It's required.

## To Do

- Organize dependencies in Spoons.
- Documentation and API for the app-specific Spoons.

## API

### AppQuitter.spoon

Leverages `launchd` to quit and/or hide inactive apps.
DO NOT activate this module if you don't plan on using it along with `hs.application.watcher`, this module relies on it exclusively to update its scheduled actions as apps go in and out of focus. Without it, the timers will quickly go out of sync.
Ideally, this module's `update` method will be called in each callback of `hs.application.watcher`.

#### AppQuitter:update(event, bundleID)

Method

Updates the module's timers.

**Parameters:**

- `event` - A string, one of the `hs.application.watcher` event constants.
- `bundleID` - A string, the bundle identifier of event-triggering app.

#### AppQuitter:start([rules])

Method

Sets up and starts the module. Begins the tracking of running dock apps,
or resumes tracking of a given app if its timer is already running.

**Parameters:**

- `rules` - a table that defines inactivity periods after which an app will hide/quit. Each element must be one of 2 forms:
  - a key value pair. Each key should equal to the bundle identifier string of the app you wish to set rules for.
    - Each value must be a table containing exactly 2 key value pairs: (1) The keys, which are strings, should be named "quit" and "hide".
    - The values for each keys are integers, and they should correspond to the period (in hours) of inactivity before an action takes place.
    - For example: ["com.apple.Safari"] = {quit = 1, hide = 0.2}. This will set a rule for Safari to quit after 1 hour and hide after 12 minutes.
  - a simple string representing that target app's bundle identifier. In this case, the default hide/quit values will be applied.

**Returns:**

- the module object, for method chaining

### AppSpoonsManager.spoon

Manages the activation and deactivation of the app-specific Spoons when an app goes in and out of focus, respectively.

#### AppSpoonsManager:update(appObj, bundleID)

Method

Calls the `start()` method of the Spoon for the focused app, and calls `exit()` on all other Spoons. This method must be called in each callback of your `hs.application.watcher` instance.

**Parameters:**

- `appObj` - the `hs.application` object of the frontmost app.
- `bundleID` - a string, the bundle identifier of the frontmost app.

### AppWatcher.spoon

An `hs.application.watcher` instance bolstered by `hs.window.filter` to catch and react on activation of "transient" apps, such as Spotlight and the 1Password 7 mini window.

#### AppWatcher.transientApps

Variable

A table containing apps you consider to be transient and want to be taken into account by the window filter. Elements should have the same structure as the `filters` parameter of hs.window.filter `setFilters` method.

#### AppWatcher.stop()

Method

Stops the module.

#### AppWatcher:start()

Method

Starts the module.

### AppearanceWatcher.spoon

Perform actions when the system's theme changes. Actions can be configured by editing the shell script inside the Spoon's directory.

#### AppearanceWatcher:stop()

Method

Stops this module.

#### AppearanceWatcher:start()

Method

starts this module.

#### AppearanceWatcher:toggle()

Method

Toggles this module.

#### AppearanceWatcher:isActive()

Method

Determines whether module is active.

**Returns:**

- A boolean, true if the module's watcher is active, otherwise false

### BrightnessControl.spoon

Enters a transient mode in which the left and right arrow keys decrease and increase the system's brightness, respectively.

#### BrightnessControl:start()

Method

Starts the module.

#### BrightnessControl:stop()

Method

Stops the module. Bound to the escape and return keys.

#### BrightnessControl.increaseBrightnessKey

Variable

A hotkey that increases brightness. It's a table that must include 2 keys, "mods" and "key", each must be of the same type as the first 2 parameters to the `hs.hotkey.bind` method. Defaults to →.

#### BrightnessControl.decreaseBrightnessKey

Variable

A hotkey that decreases brightness. It's a table that must include 2 keys, "mods" and "key", each must be of the same type as the first 2 parameters to the `hs.hotkey.bind` method. Defaults to ←.

### ConfigWatcher.spoon

Reload the environment when .lua files in ~/.hammerspoon are modified.

#### ConfigWatcher.toggle()

Method

Toggles the module.

#### ConfigWatcher.stop()

Method

Stops the module.

#### ConfigWatcher.start()

Method

Starts the module.

#### ConfigWatcher.isActive()

Method

**Returns:**

- A boolean, true if the module is active, otherwise false

### DownloadsWatcher.spoon

Monitor the ~/Downloads folder, and execute a shell script that accepts newly downloaded files as arguments.
The script can be found in the Spoon's folder.

#### DownloadsWatcher:stop()

Method

Stops the module.

#### DownloadsWatcher:start()

Method

Starts the module.

### Globals.spoon

Miscellaneous automations that are not app-specific.

#### Globals:bindHotKeys(\_mapping)

Method

This module offers the following functionalities:

- rightClick - simulates a control-click on the currently focused UI element.
- focusMenuBar - clicks the menu bar item that immediately follows the  menu bar item.
- focusDock - shows the system-wide dock.

**Parameters:**

- `_mapping` - A table that conforms to the structure described in the Spoon plugin documentation.

### KeyboardLayoutManager.spoon

A module that handles automatic keyboard layout switching under varying contexts.
Features:

- Saves the last used layout in a given app, and switches back to that layout when that app activates.
- Switches by default to "ABC" if there's no saved setting for a given app.
- Default switching behavior can be overridden for specific apps.
- For Safari, the switching behavior is tweaked so layout is saved and cycled on a per-tab basis. Needs \_Safari.spoon.

#### KeyboardLayoutManager:setInputSource(bundleid)

Method

Switch to an app's last used keyboard layout. Typically, called in an app watcher callback for the activated app.

**Parameters:**

- `bundleid` - a string, the bundle identifier of the app.

#### KeyboardLayoutManager:bindHotkeys(mapping)

Method

Binds hotkeys for this module

**Parameters:**

- `mapping` - A table containing hotkey modifier/key details for the following items:
- `toggleInputSource` - switch between the "Hebrew" and "ABC" layouts.

### NotificationCenter.spoon

Notification Center automations.

#### NotificationCenter:bindHotkeys(\_mapping)

Method

Bind hotkeys for this module. The `_mapping` table keys correspond to the following functionalities:

- `firstButton` - clicks on the first (or only) button of a notification center banner. If banners are configured through system preferences to be transient, a mouse move operation will be performed first to try and reveal the button, should it exists.
- `secondButton` - clicks on the second button of a notification center banner. If banners are configured through system preferences to be transient, a mouse move operation will be performed first to try and reveal the button, should it exists. If the button is in fact a menu button (that is, it offers a dropdown of additional options), revealing the menu will be favored over a simple click.
- `toggle` - reveals the notification center itself (side bar). Once revealed, a second call of this function will switch between the panel's 2 different modes ("Today" and "Notifications"). Closing the panel could be done normally, e.g. by pressing escape.

**Parameters:**

- `_mapping` - see the Spoon plugin documentation for the implementation.

### StatusBar.spoon

Enables a status menu item with the familiar Hammerspoon logo, but with customizable contents and a flashing mode to signal ongoing operations.

### VolumeControl.spoon

Clicks on the "volume" status bar item to reveal its volume slider, and enters a modal that allows to control the slider with the arrow keys.

#### VolumeControl:start()

Method

Activates the modules and enters the modal. The following hotkeys/functionalities are available:

- →: increase volume by a level.
- ←: decrease volume by a level.
- ⇧→: increase volume by a couple of levels.
- ⇧←: decrease volume by a couple of levels.
- ⌥→: set volume to 100.
- ⌥←: set volume to 0.
- escape: close the volume menu and exit the modal (the modal will be exited anyway as soon as the volume menu is closed).

### WifiWatcher.spoon

Respond to changes in the current Wi-Fi network.

#### WifiWatcher:userCallback()

Method

A callback to run when the Wi-Fi changes.

**Returns:**

- the module object, for method chaining.

#### WifiWatcher:start()

Method

Starts the Wi-Fi watcher.

**Returns:**

- the module object, for method chaining.

#### WifiWatcher:stop()

Method

Stops the Wi-Fi watcher.

**Returns:**

- the module object, for method chaining.

#### WifiWatcher:isActive()

Method

**Returns:**

- A boolean, true if the watcher is active, otherwise false.

#### WifiWatcher:toggle()

Method

Toggles the watcher.

**Returns:**

- the module object, for method chaining.

### WindowManager.spoon

Moves and resizes windows.
Features:

- Every window can be resized to be a quarter, half or the whole of the screen.
- Every window can be positioned anywhere on the screen, WITHIN the constraints of a grid. The grids are 1x1, 2x2 and 4x4 for maximized, half-sized and quarter-sized windows, respectively.
- Any given window can be cycled through all sizes and locations with just 4 keys. For example: northwest quarter → northeast quarter → right half ↓ southeast quarter ↓ bottom half ↓ full-screen.

#### WindowManager:bindHotKeys(\_mapping)

Method

This module offers the following functionalities:

- `maximize` - maximizes the frontmost window. If it's already maximized, it will be centered and resized to be a quarter of the screen.
- `pushLeft` - moves and/or resizes a window towards the left of the screen.
- `pushRight` - moves and/or resizes a window towards the right of the screen.
- `pushDown` - moves and/or resizes a window towards the bottom of the screen.
- `pushUp` - moves and/or resizes a window towards the top of the screen.
- `pushLeft` - moves and/or resizes a window towards the left of the screen.
- `center` - centers the frontmost window.

**Parameters:**

- `_mapping` - A table that conforms to the structure described in the Spoon plugin documentation.

### WindowManagerModal.spoon

Enables modal hotkeys that allow for more granular control over the size and position of the frontmost window. Shows a small window that serves as a cheat sheet.

### \_1Password7.spoon

1Password automations.

### \_ActivityMonitor.spoon

Activity Monitor.app automations.

### \_AdobeIllustrator.spoon

Adobe Illustrator automations.

### \_AdobeInDesign.spoon

Adobe InDesign automations.

### \_AppStore.spoon

AppStore automations.

### \_Dash.spoon

Dash (version 5 of later) automations.

### \_Finder.spoon

Finder automations.

#### \_Finder:bindModalHotkeys(hotkeysTable)

Method

**Parameters:**

- `hotkeysTable` - A table of key value pairs. The hotkeys to be toggled when the target app activates.
  - Each value is a table (as per the `hs.hotkey.bind` constructor) defining the hotkey of choice.
  - Each key is the name of the function to be executed by the hotkey.
  - No hotkeys are bound by default. Leave as is to disable.

This module offers the following functionalities:

- `browseInLaunchBar` - shows files of the current folder in LaunchBar. Requires my [LaunchBar actions](https://github.com/roeybiran/launchbar-actions).
- `focusMainArea` - focuses on Finder's main area - the files area.
- `newWindow` - ensure a new window is opened rather than a tab. Relevant when the "Prefer tabs" is set to "Always" in the Dock preference pane.
- `undoCloseTab` - undo the closing of the last tab. Requires Default Folder X.
- `moveFocusToFilesAreaIfInSearchMode` - while in search view and the search field is focused, moves focus to the first result/file.
- `showOriginalFile` - show the origin of an alias/symlink.
- `openInNewTab` - opens the selected folder in a new tab.
- `openPackage` - browses the inside of a package/bundle, rather than opens it.
- `rightSizeColumnAllColumns` - in columns view, right sizes all columns.
- `rightSizeColumnThisColumn` - in columns view, right sizes the active/selected column. In list view, right sizes the first column.

### \_Hammerspoon.spoon

Hammerspoon (console) automations

### \_Mail.spoon

Mail.app automations.

### \_Messages.spoon

Messages.app automations.

### \_Notes.spoon

Notes.app automations.

### \_Safari.spoon

Safari automations.

#### \_Safari:bindModalHotkeys(hotkeysTable)

Method

**Parameters:**

- `hotkeysTable` - A table of key value pairs. The hotkeys to be toggled when the target app activates.
  - Each value is a table (as per the `hs.hotkey.bind` constructor) defining the hotkey of choice.
  - Each key is the name of the function to be executed by the hotkey.
  - No hotkeys are bound by default. Leave as is to disable.

This module offers the following functionalities:

- `moveTabLeft` - moves the focused tab one position to the left.
- `moveTabRight` - moves the focused tab one position to the right.
- `newWindow` - ensures a new window will be opened rather than a tab. Useful when the "Prefer tabs" setting in the Dock Preference Pane is set to "always".
- `goToFirstInputField` - focuses a web page's first text field.
- `goToNextPage` - navigates to a web page's next page, if applicable.
- `goToPreviousPage` - navigates to a web page's previous page, if applicable.
- `moveFocusToMainAreaAndChangeToABCAfterOpeningLocation` - unfocuses the address bar (if focused) after loading a web page. Useful when using Vimari's hints feature, which doesn't work with the address bar focused.
- `changeToABCAfterFocusingAddressBar` - changes the active keyboard layout to ABC once the address bar has gained focus.
- `focusSidebar` - focuses the side bar.
- `focusMainArea` - focuses the main area, that is, the web page.
- `newBookmarksFolder` - creates a new bookmarks folder. Works only while viewing bookmarks.
- `rightSizeBookmarksOrHistoryColumn` - sizes to fit the first column of the bookmarks/history view.
- `firstSearchResult` - in a history/bookmarks view and when the search field is focused, moves focus the 1st search result.
