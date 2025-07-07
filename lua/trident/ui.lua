local manager = require("trident.manager")
local M = {}

local state = {
	buf = nil,
	win = nil,
	marks = {},
}

local function shorten_path(path)
	local cwd = vim.fn.getcwd()
	if vim.startswith(path, cwd) then
		local shortened = path:sub(#cwd + 2)
		return shortened
	end
	return path
end

vim.keymap.set("n", "T", function()
	local trident = require("trident")
	trident._opts.shorten_paths = not trident._opts.shorten_paths

	local opts = trident._opts
	local lines = {}
	for _, path in ipairs(state.marks) do
		if opts.shorten_paths then
			table.insert(lines, shorten_path(path))
		else
			table.insert(lines, path)
		end
	end
	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	require("trident").notify("Shorten paths " .. (opts.shorten_paths and "enabled" or "disabled"))
end, { buffer = state.buf, nowait = true, silent = true })

local function refresh_buffer()
	vim.bo[state.buf].modifiable = true

	local opts = require("trident")._opts
	local lines = {}
	for _, path in ipairs(state.marks) do
		if opts.shorten_paths then
			table.insert(lines, shorten_path(path))
		else
			table.insert(lines, path)
		end
	end
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

	vim.bo[state.buf].modifiable = false
end

function M.open_picker()
	local marks = manager.get_marks()
	-- if #marks == 0 then
	-- 	require("trident").notify("No files in Trident list", vim.log.levels.INFO)
	-- end
	-- 	return

	local opts = require("trident")._opts
	local total_lines = vim.o.lines
	local height = math.floor(total_lines * (opts.height or 0.4))
	local buf_split = opts.win.buf_split or "belowright"

	-- buf or float
	local win_type = opts.win.win_type or "buf"

	-- vim.cmd(buf_split .. " " .. height .. "split")
	--
	-- local buf = vim.api.nvim_create_buf(false, true)
	-- local win = vim.api.nvim_get_current_win()
	-- vim.api.nvim_win_set_buf(win, buf)

	local buf = vim.api.nvim_create_buf(false, true)
	local win

	if win_type == "float" then
		local float_opts = opts.win.float or {}

		local width = math.floor((float_opts.width or 0.6) * vim.o.columns)
		local height_px = math.floor((float_opts.height or 0.4) * vim.o.lines)
		local row = math.floor((vim.o.lines - height_px) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			row = row,
			col = col,
			width = width,
			height = height_px,
			style = "minimal",
			border = float_opts.border or "rounded",
			title = float_opts.title or "[♆ TRIDENT ♆]",
			title_pos = "center",
			noautocmd = true,
		})

		if float_opts.transparent then
			vim.wo[win].winhl = "Normal:NormalFloat"
		end
	else
		vim.cmd(buf_split .. " " .. height .. "split")
		win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, buf)
	end

	pcall(vim.api.nvim_buf_set_name, buf, "[♆ TRIDENT ♆]")

	vim.keymap.set("n", "j", "<Down>", { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "k", "<Up>", { buffer = buf, nowait = true, silent = true })

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

	vim.keymap.set("n", "<CR>", function()
		local idx = get_cursor_idx()
		local file = state.marks[idx]
		if file and vim.fn.filereadable(file) == 1 then
			vim.cmd("bd!")
			vim.cmd("edit " .. vim.fn.fnameescape(file))
		else
			require("trident").notify("Invalid file", vim.log.levels.ERROR)
		end
	end, { buffer = buf })

	vim.keymap.set("n", "D", function()
		local idx = get_cursor_idx()
		table.remove(state.marks, idx)
		refresh_buffer()
	end, { buffer = buf })

	vim.keymap.set("n", "J", function()
		local idx = get_cursor_idx()
		if idx < #state.marks then
			state.marks[idx], state.marks[idx + 1] = state.marks[idx + 1], state.marks[idx]
			refresh_buffer()
			vim.api.nvim_win_set_cursor(0, { idx + 1, 0 })
		end
	end, { buffer = buf })

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
		require("trident").notify("Trident list saved.")
		vim.cmd("bd!")
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "Q", function()
		vim.cmd("bd!")
		require("trident").notify("Trident list closed without saving.")
	end, { buffer = buf, nowait = true, silent = true })
end

return M
