#!/bin/bash

shopt -s nocasematch

export PATH="$PATH:/bin:/usr/bin"

SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; do
	DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
	SOURCE="$(readlink "$SOURCE")"
	# if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$(dirname "${SOURCE}")"

path="${1}"
parsepath() {
	dir="$(dirname "${1}")"
	name_no_ext="$(basename "${1}" | cut -f 1 -d '.')"
	printf "%s\n" "${dir}/${name_no_ext}"
}


output=""
case "${path}" in
*".zip")
	# a naive check for a wordpress plugin
	# TODO: find a better solution
	# if unzip -l "${path}" | grep php; then
		# echo "Skipping unarchiving a WordPress plugin/theme"
		# exit 0
	# fi
	target="$(parsepath "${path}")"
	mkdir -p "${target}"
	ditto -xk "${path}" "${target}"
	output="${target}"
	mv -f "${path}" ~/.Trash/
	;;
*".tgz" | *".gz")
	tar_output=$(tar -xvf "${path}" -C ~/Downloads)
	output=$(printf "%s\n" "${tar_output}" | sed 's/x //' | sed -E '/^\.\//d' | sed -E "s|^|${HOME}/Downloads/|")
	mv -f "${path}" ~/.Trash/
	;;
*".dmg")
	mounted_path=$(yes | hdiutil attach -nobrowse "${path}" | tail -n 1 | grep -E -o "/Volumes/.+$")
	cp -R "${mounted_path}" ~/Downloads
	output=~/Downloads/$(basename "${mounted_path}")
	hdiutil detach "${mounted_path}" 1>/dev/null
	mv -f "${path}" ~/.Trash/
	;;
*".heic")
	output="$(parsepath "${path}").jpg"
	sips -s format jpeg "${path}" --out "${output}"
	mv -f "${path}" ~/.Trash/
	;;
*)
	output="${path}"
	;;
esac
printf "%s\n" "${output}"
