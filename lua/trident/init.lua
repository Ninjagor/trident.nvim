local manager = require("trident.manager")

local M = {}

M.add = function(filepath)
	if filepath == nil or filepath == "" then
		filepath = vim.api.nvim_buf_get_name(0)
	end
	manager.add_file(filepath)
end

M.remove = function(filepath)
	if filepath == nil or filepath == "" then
		filepath = vim.api.nvim_buf_get_name(0)
	end
	manager.remove_file(filepath)
end

M.get_all = function()
	return manager.get_marks()
end

M.purge = function()
	manager.purge_project()
end

M.move = function(from, to)
	require("trident.manager").move(from, to)
end

M.ui = require("trident.ui")

M.list = function()
	M.ui.open_picker()
end

return M
