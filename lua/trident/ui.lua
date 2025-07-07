local manager = require("trident.manager")
local M = {}

function M.open_picker()
	local marks = manager.get_marks()
	if #marks == 0 then
		vim.notify("No files in Trident list", vim.log.levels.INFO)
		return
	end

	-- Create new split
	vim.cmd("belowright 10split")
	local buf = vim.api.nvim_create_buf(false, true) -- [listed=false, scratch=true]
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	vim.bo[buf].filetype = "trident"

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, marks)
	vim.bo[buf].modifiable = false

	-- On Enter: jump to selected file and close buffer
	vim.keymap.set("n", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(0)[1]
		local file = marks[cursor]
		if file and vim.fn.filereadable(file) == 1 then
			vim.cmd("bd!") -- close picker buffer
			vim.cmd("edit " .. vim.fn.fnameescape(file))
		else
			vim.notify("Invalid file", vim.log.levels.ERROR)
		end
	end, { buffer = buf, nowait = true, silent = true })
end

return M
