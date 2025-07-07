local storage = require("trident.storage")
local uv = vim.loop
local M = {}

local marks = storage.load()

local function normalize_path(path)
	return vim.fn.fnamemodify(path, ":p")
end

local function exists(path)
	for _, item in ipairs(marks) do
		if item == path then
			return true
		end
	end
	return false
end

local function index_of(path)
	for i, item in ipairs(marks) do
		if item == path then
			return i
		end
	end
	return nil
end

function M.get_marks()
	return marks
end

function M.add_file(filepath)
	filepath = normalize_path(filepath)
	local stat = uv.fs_stat(filepath)
	if not stat or stat.type ~= "file" then
		vim.notify("Not a valid file: " .. filepath, vim.log.levels.ERROR)
		return
	end

	if exists(filepath) then
		vim.notify("File already in trident: " .. filepath, vim.log.levels.INFO)
		return
	end

	table.insert(marks, filepath)
	storage.save(marks)
	vim.notify("Added: " .. filepath)
end

function M.remove_file(filepath)
	filepath = normalize_path(filepath)
	local idx = index_of(filepath)
	if not idx then
		vim.notify("File not in trident: " .. filepath, vim.log.levels.WARN)
		return
	end
	table.remove(marks, idx)
	storage.save(marks)
	vim.notify("Removed: " .. filepath)
end

function M.move(from_idx, to_idx)
	if from_idx < 1 or from_idx > #marks or to_idx < 1 or to_idx > #marks then
		vim.notify("Invalid indices for reorder", vim.log.levels.ERROR)
		return
	end
	local item = table.remove(marks, from_idx)
	table.insert(marks, to_idx, item)
	storage.save(marks)
	vim.notify("Moved mark to position " .. to_idx)
end

function M.purge_project()
	marks = {}
	storage.purge()
end

return M
