local FS = require "hs.fs"
local Task = require "hs.task"

--- helpers
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

local function stripExtension(path)
	local splitted = hs.fnutils.split(path, ".", true)
	return table.unpack(splitted, 1, #splitted - 1)
end

local trash = os.getenv "HOME" .. "/.Trash/"
---

local function moveToTrash(path)
	local _displayName = FS.displayName(path)
	os.rename(path, trash .. _displayName)
end

local function convertToJpg(path)
	local target = stripExtension(path) .. ".jpg"
	Task.new(
		"/usr/bin/sips",
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
	Task.new(
		"/usr/bin/ditto",
		function()
			moveToTrash(path)
		end,
		{"-xk", path, nameWithoutExt}
	):start()
end

local function handleDmg(path)
	Task.new(
		script_path() .. "handle_dmg.sh",
		function(exit, out, err)
			print(exit, out, err)
		end,
		{path}
	):start()
end

return {
	{
		patterns = {".DS_Store", ".localized", ".", ".."},
		isRegex = false,
		fn = nil
	},
	{
		patterns = {"%.crdownload$", "%.download$"},
		isRegex = true,
		fn = nil
	},
	{
		patterns = {"%.ics$"},
		isRegex = true,
		fn = hs.open
	},
	{
		patterns = {"%.heic$", "%.webp$"},
		isRegex = true,
		fn = convertToJpg
	},
	{
		patterns = {"%.jpeg$"},
		isRegex = true,
		fn = renameJpegToJpg
	},
	{
		patterns = {"%.zip$"},
		isRegex = true,
		fn = handleZip
	},
	{
		patterns = {"%.pdf$"},
		isRegex = true,
		fn = function(path)
			handlePdf(path, pdfRenamingRules)
		end
	},
	{
		patterns = {"%.tgz$", "%.gz$"},
		isRegex = true,
		fn = handleGz
	},
	{
		patterns = {"%.dmg$"},
		isRegex = true,
		fn = handleDmg
	}
}
