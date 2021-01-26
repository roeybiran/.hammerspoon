#!/bin/sh

MODE="$1"

if [ "$MODE" != light ] && [ "$MODE" != dark ]; then
	printf "%s\n" "USAGE: $(basename "$SOURCE") (dark|light)"
	exit 0
fi

### contexts ###
if [ "$MODE" = dark ]; then
	contexts_theme=CTAppearanceNamedVibrantDark
elif [ "$MODE" = light ]; then
	contexts_theme=CTAppearanceNamedSubtle
fi

if [ "$(defaults read com.contextsformac.Contexts CTAppearanceTheme)" != "$contexts_theme" ]; then
	defaults write com.contextsformac.Contexts CTAppearanceTheme -string "$contexts_theme"
	killall Contexts
	sleep 1
	open -a Contexts
	sleep 1
	osascript -e 'tell application "System Events" to click button 1 of window 1 of application process "Contexts"'
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
