#!/bin/bash

path="$1"
mounted_path=$(yes | hdiutil attach -nobrowse "${path}" | tail -n 1 | grep -E -o "/Volumes/.+$")
cp -R "${mounted_path}" ~/Downloads
# output=~/Downloads/$(basename "${mounted_path}")
hdiutil detach "${mounted_path}" 1>/dev/null
mv -f "${path}" ~/.Trash/
