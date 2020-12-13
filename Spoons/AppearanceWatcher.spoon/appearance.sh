#!/bin/bash

MODE="${1}"

if [[ "${MODE}" != "light" ]] && [[ "${MODE}" != "dark" ]]; then
	printf "%s\n" "USAGE: $(basename "${SOURCE}") (dark|light)"
	exit 0
fi

### contexts ###
if [[ "${MODE}" == "dark" ]]; then
	contexts_theme="CTAppearanceNamedVibrantDark"
elif [[ "${MODE}" == "light" ]]; then
	contexts_theme="CTAppearanceNamedSubtle"
fi
if [[ "$(defaults read "com.contextsformac.Contexts" CTAppearanceTheme)" != "${contexts_theme}" ]]; then
	defaults write "com.contextsformac.Contexts" CTAppearanceTheme -string "${contexts_theme}"
	killall "Contexts"
	sleep 1
	open -a "Contexts"
	sleep 1
	osascript -e 'tell application "System Events" to click button 1 of window 1 of application process "Contexts"'
fi

# ### whatsapp ###
# ~/Library/Containers/desktop.WhatsApp/Data/Library/Application Support/WhatsApp

### launchbar ###
if [[ "${MODE}" == "dark" ]]; then
	launchbar_theme="at.obdev.LaunchBar.theme.Dark"
elif [[ "${MODE}" == "light" ]]; then
	launchbar_theme="at.obdev.LaunchBar.theme.Default"
fi
defaults write "at.obdev.LaunchBar" Theme -string "${launchbar_theme}"

# hammerspoon's console
if [[ "${MODE}" == "dark" ]]; then
	HS="true"
elif [[ "${MODE}" == "light" ]]; then
	HS="false"
fi
osascript -e "tell application \"Hammerspoon\" to execute lua code \"hs.console.darkMode(${HS})\""

### iterm ###
if pgrep "iTerm"; then
	osascript -e 'tell application "iTerm" to launch API script named "changeColorPreset.py"'
fi

### vscode ###
if [[ "${MODE}" == "dark" ]]; then
	vscode_theme="Solarized Dark"
elif [[ "${MODE}" == "light" ]]; then
	vscode_theme="Solarized Light"
fi
vscode_settings_file="${HOME}/Library/Application Support/Code/User/settings.json"
if ! grep --silent "\"workbench.colorTheme\": \"${vscode_theme}\"" "${vscode_settings_file}"; then
	sed -E -i .bak "s|(\"workbench.colorTheme\":).+$|\1 \"${vscode_theme}\",|" "${vscode_settings_file}"
fi

# ### restart whatsapp when transitioning to dark mode ###
# if [[ "${MODE}" == "dark" ]]; then
# 	if pgrep "WhatsApp"; then
# 		killall -9 "WhatsApp"
# 		sleep 1
# 		open -jga "WhatsApp"
# 		sleep 1
# 		osascript <<-EOF
# 			tell application "System Events"
# 				tell application process "WhatsApp"
# 					set visible to false
# 				end tell
# 			end tell
# 		EOF
# 	fi
# fi
