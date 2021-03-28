#!/bin/sh

MODE="$1"

if [ "$MODE" != light ] && [ "$MODE" != dark ]; then
	printf "%s\n" "USAGE: $(basename "$SOURCE") (dark|light)"
	exit 0
fi

### launchbar ###
if [ "$MODE" = dark ]; then
	launchbar_theme=at.obdev.LaunchBar.theme.Dark
elif [ "$MODE" = light ]; then
	launchbar_theme=at.obdev.LaunchBar.theme.Default
fi
defaults write at.obdev.LaunchBar Theme -string "$launchbar_theme"

# hammerspoon's console
if [ "$MODE" = dark ]; then
	HS="true"
elif [ "$MODE" = light ]; then
	HS="false"
fi
osascript -e "tell application \"Hammerspoon\" to execute lua code \"hs.console.darkMode($HS)\""
