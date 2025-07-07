local manager = require("trident.manager")
local M = {}

-- Shared state inside UI session
local state = {
	buf = nil,
	win = nil,
	marks = {},
}

local function refresh_buffer()
	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, state.marks)
	vim.bo[state.buf].modifiable = false
end

function M.open_picker()
	local marks = manager.get_marks()
	if #marks == 0 then
		vim.notify("No files in Trident list", vim.log.levels.INFO)
		return
	end

	vim.cmd("belowright 10split")
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	vim.bo[buf].buftype = "nofile"

	-- vim.bo[buf].buftype = ""
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "trident"

	state.buf = buf
	state.win = win
	state.marks = vim.deepcopy(marks)

	refresh_buffer()

	local function get_cursor_idx()
		return vim.api.nvim_win_get_cursor(0)[1]
	end

	-- Open file
	vim.keymap.set("n", "<CR>", function()
		local idx = get_cursor_idx()
		local file = state.marks[idx]
		if file and vim.fn.filereadable(file) == 1 then
			vim.cmd("bd!") -- close picker buffer
			vim.cmd("edit " .. vim.fn.fnameescape(file))
		else
			vim.notify("Invalid file", vim.log.levels.ERROR)
		end
	end, { buffer = buf })

	-- Delete mark
	vim.keymap.set("n", "D", function()
		local idx = get_cursor_idx()
		table.remove(state.marks, idx)
		refresh_buffer()
	end, { buffer = buf })

	-- Move down
	vim.keymap.set("n", "J", function()
		local idx = get_cursor_idx()
		if idx < #state.marks then
			state.marks[idx], state.marks[idx + 1] = state.marks[idx + 1], state.marks[idx]
			refresh_buffer()
			vim.api.nvim_win_set_cursor(0, { idx + 1, 0 })
		end
	end, { buffer = buf })

	-- Move up
	vim.keymap.set("n", "K", function()
		local idx = get_cursor_idx()
		if idx > 1 then
			state.marks[idx], state.marks[idx - 1] = state.marks[idx - 1], state.marks[idx]
			refresh_buffer()
			vim.api.nvim_win_set_cursor(0, { idx - 1, 0 })
		end
	end, { buffer = buf })

	vim.keymap.set("n", "W", function()
		manager.set_marks(state.marks)
		vim.notify("Trident list saved.")
		vim.cmd("bd!")
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "Q", function()
		vim.cmd("bd!")
		vim.notify("Trident list closed without saving.")
	end, { buffer = buf, nowait = true, silent = true })
end

return M
