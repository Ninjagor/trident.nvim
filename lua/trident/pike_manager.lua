local storage = require("trident.pikes_storage")
local uv = vim.loop
local M = {}

local pikes = storage.load()

local function normalize_path(path)
	return vim.fn.fnamemodify(path, ":p")
end

local function exists(pike)
	for _, item in ipairs(pikes) do
		if item.filepath == pike.filepath and item.line == pike.line then
			return true
		end
	end
	return false
end

function M.get_pikes()
	return pikes
end

function M.get_pikes_for_file(filepath)
	filepath = normalize_path(filepath)
	local filtered = {}
	for _, pike in ipairs(pikes) do
		if pike.filepath == filepath then
			table.insert(filtered, pike)
		end
	end
	return filtered
end

function M.add_pike(pike)
	pike.filepath = normalize_path(pike.filepath)
	if not uv.fs_stat(pike.filepath) then
		require("trident").notify("File does not exist: " .. pike.filepath, vim.log.levels.ERROR)
		return
	end
	if type(pike.line) ~= "number" or pike.line < 1 then
		require("trident").notify("Invalid line number", vim.log.levels.ERROR)
		return
	end
	if exists(pike) then
		require("trident").notify("Pike already exists at this location", vim.log.levels.INFO)
		return
	end
	table.insert(pikes, pike)
	storage.save(pikes)
	require("trident").notify("Added pike: " .. (pike.name or "") .. " at " .. pike.filepath .. ":" .. pike.line)
end

function M.remove_pike(pike)
	for i, item in ipairs(pikes) do
		if item.filepath == pike.filepath and item.line == pike.line then
			table.remove(pikes, i)
			storage.save(pikes)
			require("trident").notify("Removed pike at " .. pike.filepath .. ":" .. pike.line)
			return
		end
	end
	require("trident").notify("Pike not found", vim.log.levels.WARN)
end

function M.purge()
	pikes = {}
	storage.purge()
end

return M
