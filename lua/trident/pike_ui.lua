local utils = require("trident.util")

local M = {}

function M.place_pike_signs(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local pikes = require("trident.pike_manager").get_pikes_for_file(filepath)

	vim.fn.sign_unplace("trident_pikes", { buffer = bufnr })

	local ns = vim.api.nvim_create_namespace("trident_pikes_virtualtext")
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	for i, pike in ipairs(pikes) do
		vim.fn.sign_place(
			i,
			"trident_pikes",
			"TridentPikeSign" .. pike.letter,
			bufnr,
			{ lnum = pike.line, priority = 10 }
		)
		-- vim.fn.sign_place(i, "trident_pikes", "TridentPikeSign", bufnr, { lnum = pike.line, priority = 10 })

		if
			pike.type == "todo"
			or pike.type == "error"
			or pike.type == "warn"
			or pike.type == "note"
			or pike.type == "fix"
			or pike.type == "debug"
			or pike.type == "bookmark"
			or pike.type == "perf"
			or pike.type == "hack"
		then
			local pike_type_caps = string.upper(pike.type)
			vim.api.nvim_buf_set_extmark(bufnr, ns, pike.line - 1, 0, {
				virt_text = { { " ♆ " .. pike_type_caps .. " ♆ ", "TridentPikeVirtualText" } },
				virt_text_pos = "eol",
				hl_mode = "combine",
			})
		end
	end
end

function M.open_picker()
	local pike_manager = require("trident.pike_manager")
	local trident = require("trident")
	local utils = require("trident.util")

	local opts = trident._opts
	local win_type = opts.win.win_type or "buf"
	local buf_split = opts.win.buf_split or "belowright"
	local float_opts = opts.win.float or {}

	local show_all = false

	local current_bufnr = vim.api.nvim_get_current_buf()
	local current_filepath = vim.api.nvim_buf_get_name(current_bufnr)

	local function get_display_pikes()
		local all_pikes = pike_manager.get_pikes()
		if show_all then
			return utils.shallow_copy(all_pikes)
		else
			local filtered = {}
			for _, p in ipairs(all_pikes) do
				if p.filepath == current_filepath then
					table.insert(filtered, p)
				end
			end
			return filtered
		end
	end

	local all_pikes = get_display_pikes()

	local function update_lines()
		local lines = {}
		for _, p in ipairs(all_pikes) do
			local short = vim.fn.fnamemodify(p.filepath, ":~:.")
			local label =
				string.format("%s [%s] %s:%d", p.letter, (p.type and (p.type .. " pike") or "pike"), short, p.line)
			if p.name then
				label = label .. " - " .. p.name
			end
			table.insert(lines, label)
		end
		return lines
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local win

	if win_type == "float" then
		local width = math.floor((float_opts.width or 0.6) * vim.o.columns)
		local height = math.floor((float_opts.height or 0.4) * vim.o.lines)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			row = row,
			col = col,
			width = width,
			height = height,
			style = "minimal",
			border = float_opts.border or "single",
			title = float_opts.title or "[♆ TRIDENT PIKES ♆]",
			title_pos = "center",
			noautocmd = true,
		})
	else
		local height = math.floor(vim.o.lines * (opts.height or 0.4))
		vim.cmd(buf_split .. " " .. height .. "split")
		win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, buf)
	end

	pcall(vim.api.nvim_buf_set_name, buf, "[♆ TRIDENT PIKES ♆]")
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "trident_pikes"

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, update_lines())
	vim.bo[buf].modifiable = false

	local function get_cursor_idx()
		return vim.api.nvim_win_get_cursor(0)[1]
	end

	local function refresh()
		all_pikes = get_display_pikes()
		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, update_lines())
		vim.bo[buf].modifiable = false
	end

	vim.keymap.set("n", "j", "<Down>", { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "k", "<Up>", { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "<CR>", function()
		local idx = get_cursor_idx()
		local pike = all_pikes[idx]
		if not pike then
			return
		end
		local float_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_close(float_win, true)

		vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
		vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
	end, { buffer = buf })

	vim.keymap.set("n", "D", function()
		local idx = get_cursor_idx()
		local pike = all_pikes[idx]
		if not pike then
			return
		end

		vim.bo[buf].modifiable = true
		require("trident").remove_pike({ letter = pike.letter })

		refresh()
	end, { buffer = buf })

	vim.keymap.set("n", "J", function()
		local idx = get_cursor_idx()
		if idx < #all_pikes then
			all_pikes[idx], all_pikes[idx + 1] = all_pikes[idx + 1], all_pikes[idx]

			vim.bo[buf].modifiable = true
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, update_lines())
			vim.bo[buf].modifiable = false

			vim.api.nvim_win_set_cursor(0, { idx + 1, 0 })
		end
	end, { buffer = buf })

	vim.keymap.set("n", "K", function()
		local idx = get_cursor_idx()
		if idx > 1 then
			all_pikes[idx], all_pikes[idx - 1] = all_pikes[idx - 1], all_pikes[idx]

			vim.bo[buf].modifiable = true
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, update_lines())
			vim.bo[buf].modifiable = false

			vim.api.nvim_win_set_cursor(0, { idx - 1, 0 })
		end
	end, { buffer = buf })

	vim.keymap.set("n", "W", function()
		pike_manager.set_pikes(all_pikes)
		vim.cmd("bd!")
		trident.notify("Pikes saved")
	end, { buffer = buf })

	vim.keymap.set("n", "Q", function()
		vim.cmd("bd!")
		trident.notify("Pike list closed without saving")
	end, { buffer = buf })

	vim.keymap.set("n", "Z", function()
		show_all = not show_all
		refresh()
		local mode = show_all and "Workspace" or "Buffer"
		trident.notify("Showing " .. mode .. " pikes")
	end, { buffer = buf })
end

return M
