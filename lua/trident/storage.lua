local util = require("trident.util")
local M = {}

local base_dir = vim.fn.stdpath("data") .. "/trident"

local function ensure_dir()
	if vim.fn.isdirectory(base_dir) == 0 then
		vim.fn.mkdir(base_dir, "p")
	end
end

local function get_project_file()
	ensure_dir()
	local cwd = vim.fn.getcwd()
	local hash = util.hash(cwd)
	return base_dir .. "/" .. hash .. ".json"
end

function M.load()
	local path = get_project_file()
	local f = io.open(path, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()
	local ok, data = pcall(vim.fn.json_decode, content)
	if not ok or type(data) ~= "table" then
		return {}
	end
	return data
end

function M.save(marks)
	local path = get_project_file()
	local content = vim.fn.json_encode(marks)
	local f = io.open(path, "w")
	if not f then
		require('trident').notify("Failed to write trident project file", vim.log.levels.ERROR)
		return
	end
	f:write(content)
	f:close()
end

function M.purge()
	local path = get_project_file()
	local ok, err = os.remove(path)
	if ok then
		require('trident').notify("Trident project storage cleared", vim.log.levels.INFO)
	else
		require('trident').notify("Failed to purge project storage: " .. (err or ""), vim.log.levels.ERROR)
	end
end

return M
