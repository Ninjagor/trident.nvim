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

local function get_next_letter()
	local used = {}
	for _, p in ipairs(pikes) do
		if p.letter then
			used[p.letter] = true
		end
	end
	for c = 97, 122 do
		local ch = string.char(c)
		if not used[ch] then
			return ch
		end
	end
	return nil
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

	if pike.letter then
		for i, existing in ipairs(pikes) do
			if existing.letter == pike.letter then
				table.remove(pikes, i)
				break
			end
		end
	else
		pike.letter = get_next_letter()
		if not pike.letter then
			require("trident").notify("No free letters for pike", vim.log.levels.ERROR)
			return
		end
	end

	for _, existing in ipairs(pikes) do
		if existing.filepath == pike.filepath and existing.line == pike.line then
			require("trident").notify("Pike already exists at this location", vim.log.levels.INFO)
			return
		end
	end

	table.insert(pikes, pike)
	storage.save(pikes)
	require("trident").notify(
		"Added pike " .. pike.letter .. ": " .. (pike.name or "") .. " at " .. pike.filepath .. ":" .. pike.line
	)
end

function M.remove_pike(opts)
	if not opts.letter then
		require("trident").notify("Letter required to remove pike", vim.log.levels.ERROR)
		return
	end
	for i, pike in ipairs(pikes) do
		if pike.letter == opts.letter then
			table.remove(pikes, i)
			storage.save(pikes)
			require("trident").notify("Removed pike " .. opts.letter)
			return
		end
	end
	require("trident").notify("No pike with letter " .. opts.letter, vim.log.levels.WARN)
end

function M.purge()
	pikes = {}
	storage.purge()
end

function M.find_by_letter(letter)
	for _, pike in ipairs(pikes) do
		if pike.letter == letter then
			return pike
		end
	end
	return nil
end

function M.get_all_sorted()
	table.sort(pikes, function(a, b)
		if a.filepath == b.filepath then
			return a.line < b.line
		else
			return a.filepath < b.filepath
		end
	end)
	return pikes
end

return M
