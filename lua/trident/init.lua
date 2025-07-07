local manager = require("trident.manager")
local pikes_manager = require("trident.pike_manager")
local pikes_ui = require("trident.pike_ui")

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

function M.add_pike(opts)
	-- opts: { filepath, line, name?, type? }
	opts.filepath = opts.filepath or vim.api.nvim_buf_get_name(0)
	pikes_manager.add_pike(opts)
	pikes_ui.place_pike_signs()
end

function M.remove_pike(opts)
	pikes_manager.remove_pike(opts)
	require("trident.pike_ui").place_pike_signs()
end

function M.get_all_pikes()
	return pikes_manager.get_pikes()
end

function M.get_pikes_for_file(filepath)
	filepath = filepath or vim.api.nvim_buf_get_name(0)
	return pikes_manager.get_pikes_for_file(filepath)
end

function M.purge_pikes()
	pikes_manager.purge()
end

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		local pikes_ui = require("trident.pike_ui")
		pikes_ui.place_pike_signs()
	end,
})

function M.jump_to_pike(letter)
	local pike = pikes_manager.find_by_letter(letter)
	if not pike then
		vim.notify("No pike with letter: " .. letter, vim.log.levels.WARN)
		return
	end
	vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
	vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
end

function M.next_pike()
	local pikes = pikes_manager.get_all_sorted()
	if #pikes == 0 then
		vim.notify("No pikes to jump to", vim.log.levels.INFO)
		return
	end

	local curr_file = vim.api.nvim_buf_get_name(0)
	local curr_line = vim.api.nvim_win_get_cursor(0)[1]

	for _, pike in ipairs(pikes) do
		if pike.filepath > curr_file or (pike.filepath == curr_file and pike.line > curr_line) then
			vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
			vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
			return
		end
	end

	local first = pikes[1]
	vim.cmd("edit " .. vim.fn.fnameescape(first.filepath))
	vim.api.nvim_win_set_cursor(0, { first.line, 0 })
end

function M.prev_pike()
	local pikes = pikes_manager.get_all_sorted()
	if #pikes == 0 then
		vim.notify("No pikes to jump to", vim.log.levels.INFO)
		return
	end

	local curr_file = vim.api.nvim_buf_get_name(0)
	local curr_line = vim.api.nvim_win_get_cursor(0)[1]

	for i = #pikes, 1, -1 do
		local pike = pikes[i]
		if pike.filepath < curr_file or (pike.filepath == curr_file and pike.line < curr_line) then
			vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
			vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
			return
		end
	end

	local last = pikes[#pikes]
	vim.cmd("edit " .. vim.fn.fnameescape(last.filepath))
	vim.api.nvim_win_set_cursor(0, { last.line, 0 })
end

function M.update_pike_type(letter, new_type)
	local ok = pikes_manager.update_type(letter, new_type)
	if ok then
		require("trident").notify("Updated pike " .. letter .. " to type: " .. new_type)
		require("trident.pike_ui").place_pike_signs()
	else
		require("trident").notify("No pike found with letter " .. letter, vim.log.levels.WARN)
	end
end

M.list_pikes = function()
	pikes_ui.open_picker()
end

return M
