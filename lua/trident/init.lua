local manager = require("trident.manager")

local M = {
	_opts = {
		cycle = false,
		height = 0.4,
		shorten_paths = false,
		silent = false,
		win = {
			-- buf or float
			win_type = "buf",

			-- for the buf wintype
			buf_split = "belowright",

			float = {
				width = 0.6,
				height = 0.4,
				border = "single",
				title = "[♆ TRIDENT ♆]",
				transparent = false,
			},
		},
	},
}

local notify = vim.notify
function M.notify(msg, level)
	if not M._opts.silent then
		notify(msg, level)
	end
end

function M.setup(opts)
	M._opts = vim.tbl_extend("force", M._opts, opts or {})
end

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

function M.next()
	local marks = manager.get_marks()
	if #marks == 0 then
		return
	end

	local current = vim.api.nvim_buf_get_name(0)
	local idx
	for i, f in ipairs(marks) do
		if f == current then
			idx = i
			break
		end
	end

	if not idx then
		vim.cmd("edit " .. vim.fn.fnameescape(marks[1]))
		return
	end

	local next_idx = idx + 1
	if next_idx > #marks then
		if M._opts.cycle then
			next_idx = 1
		else
			require("trident").notify("No next file", vim.log.levels.INFO)
			return
		end
	end
	vim.cmd("edit " .. vim.fn.fnameescape(marks[next_idx]))
end

-- Go to previous marked file
function M.prev()
	local marks = manager.get_marks()
	if #marks == 0 then
		return
	end

	local current = vim.api.nvim_buf_get_name(0)
	local idx
	for i, f in ipairs(marks) do
		if f == current then
			idx = i
			break
		end
	end

	if not idx then
		vim.cmd("edit " .. vim.fn.fnameescape(marks[#marks]))
		return
	end

	local prev_idx = idx - 1
	if prev_idx < 1 then
		if M._opts.cycle then
			prev_idx = #marks
		else
			require("trident").notify("No previous file", vim.log.levels.INFO)
			return
		end
	end
	vim.cmd("edit " .. vim.fn.fnameescape(marks[prev_idx]))
end

return M
