local storage = require("trident.storage")
local uv = vim.loop
local M = {}

local marks = storage.load()

function M.get_marks()
	return marks
end

function M.add_file(filepath)
	filepath = vim.fn.fnamemodify(filepath, ":p")
	local stat = uv.fs_stat(filepath)
	if not stat or stat.type ~= "file" then
		vim.notify("Not a valid file: " .. filepath, vim.log.levels.ERROR)
		return
	end

	if marks[filepath] then
		vim.notify("File already added: " .. filepath, vim.log.levels.INFO)
		return
	end

	marks[filepath] = true
	storage.save(marks)
	vim.notify("Added file to trident: " .. filepath)
end

function M.remove_file(filepath)
	filepath = vim.fn.fnamemodify(filepath, ":p")
	if not marks[filepath] then
		vim.notify("File not in trident: " .. filepath, vim.log.levels.WARN)
		return
	end

	marks[filepath] = nil
	storage.save(marks)
	vim.notify("Removed file from trident: " .. filepath)
end

function M.purge_project()
	marks = {}
	storage.purge()
end

return M
