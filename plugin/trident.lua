vim.api.nvim_create_user_command("TridentAdd", function(opts)
	require("trident").add(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("TridentRemove", function(opts)
	require("trident").remove(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("TridentList", function()
	require("trident").list()
end, {})

vim.api.nvim_create_user_command("TridentPurge", function()
	require("trident").purge()
end, {})

vim.api.nvim_create_user_command("TridentMove", function(opts)
	local from = tonumber(opts.fargs[1])
	local to = tonumber(opts.fargs[2])
	require("trident").move(from, to)
end, { nargs = "+" })

vim.api.nvim_create_user_command("TridentNext", function()
	require("trident").next()
end, {})

vim.api.nvim_create_user_command("TridentPrev", function()
	require("trident").prev()
end, {})

vim.api.nvim_create_user_command("PikeAdd", function(opts)
	local args = vim.split(opts.args, " ")
	local line = tonumber(args[1])
	local letter = args[2]
	if not line or line < 1 then
		vim.notify("Invalid line number", vim.log.levels.ERROR)
		return
	end
	if letter and not letter:match("^[a-z]$") then
		vim.notify("Letter must be a-z", vim.log.levels.ERROR)
		return
	end
	require("trident").add_pike({ line = line, letter = letter })
end, { nargs = "+" })

vim.api.nvim_create_user_command("PikeRemove", function(opts)
	local letter = opts.args
	if not letter or not letter:match("^[a-z]$") then
		vim.notify("Invalid letter (a-z)", vim.log.levels.ERROR)
		return
	end
	require("trident").remove_pike({ letter = letter })
end, { nargs = 1 })

vim.api.nvim_create_user_command("PikeList", function()
	local pikes = require("trident").get_pikes_for_file()
	if #pikes == 0 then
		vim.notify("No pikes in this file", vim.log.levels.INFO)
		return
	end
	for _, p in ipairs(pikes) do
		print(string.format("%d: %s", p.line, p.name or ""))
	end
end, {})

-- vim.fn.sign_define("TridentPikeSign", { text = "♆", texthl = "WarningMsg", numhl = "" })

for c = string.byte("a"), string.byte("z") do
	local letter = string.char(c)
	vim.fn.sign_define("TridentPikeSign" .. letter, { text = letter, texthl = "WarningMsg" })
end

vim.api.nvim_create_user_command("PikeJump", function(opts)
	local letter = opts.args
	if not letter or not letter:match("^[a-z]$") then
		vim.notify("Invalid letter (a-z)", vim.log.levels.ERROR)
		return
	end
	require("trident").jump_to_pike(letter)
end, { nargs = 1 })

vim.api.nvim_create_user_command("PikeNextGlobal", function()
	require("trident").next_pike()
end, {})

vim.api.nvim_create_user_command("PikePrevGlobal", function()
	require("trident").prev_pike()
end, {})

vim.api.nvim_create_user_command("PikeNext", function()
	require("trident").next_pike_local()
end, {})

vim.api.nvim_create_user_command("PikePrev", function()
	require("trident").prev_pike_local()
end, {})

vim.api.nvim_create_user_command("PikeSetType", function(opts)
	local letter = opts.fargs[1]
	local pike_type = opts.fargs[2]
	if not letter or not letter:match("^[a-z]$") or not pike_type then
		vim.notify("Usage: :PikeSetType <letter> <type>", vim.log.levels.ERROR)
		return
	end
	require("trident").update_pike_type(letter, pike_type)
end, { nargs = "+" })

vim.api.nvim_create_augroup("TridentHighlight", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
	group = "TridentHighlight",
	callback = function()
		local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
		local error_hl = vim.api.nvim_get_hl(0, { name = "Error" })

		local bg = normal_hl.fg or 0x282828
		local fg = error_hl.bg or 0xff0000

		local function to_hex(c)
			return string.format("#%06x", c)
		end

		vim.cmd(string.format("highlight TridentPikeVirtualText guifg=%s guibg=%s gui=bold", to_hex(fg), to_hex(bg)))
	end,
})

vim.cmd("doautocmd ColorScheme")

vim.api.nvim_create_user_command("PikeList", function()
	require("trident").list_pikes()
end, {})

local function is_valid_letter(c)
	return c:match("^[a-z]$") ~= nil
end

require("trident").generate_keybinds({
	create_label_prefix = "tm",
	delete_label_prefix = "td",
	jump_label_prefix = ";",
	create_typed_prefix = "tt",
	clear_type_key = "tr",
})

-- local type_map = {
-- 	t = "todo",
-- 	e = "error",
-- 	w = "warn",
-- 	n = "note",
-- 	f = "fix",
-- 	d = "debug",
-- 	b = "bookmark",
-- 	p = "perf",
-- 	h = "hack",
-- }
--
-- for c = string.byte("a"), string.byte("z") do
-- 	local trident = require("trident")
-- 	local letter = string.char(c)
-- 	local keybinds = trident._opts.pikes_keybinds
-- 	-- print(keybinds)
--
-- 	vim.api.nvim_set_keymap(
-- 		"n",
-- 		((keybinds.create_prefix or "tm") .. letter),
-- 		(
-- 			string.format(
-- 				"<cmd>lua require('trident').add_pike({ line = vim.api.nvim_win_get_cursor(0)[1], letter = '%s' })<CR>",
-- 				letter
-- 			)
-- 		),
-- 		{ noremap = true, silent = true }
-- 	)
--
-- 	vim.api.nvim_set_keymap(
-- 		"n",
-- 		((keybinds.delete_prefix or "td") .. letter),
-- 		(string.format("<cmd>lua require('trident').remove_pike({ letter = '%s' })<CR>", letter)),
-- 		{ noremap = true, silent = true }
-- 	)
--
-- 	vim.api.nvim_set_keymap(
-- 		"n",
-- 		((keybinds.jump_prefix or ";") .. letter),
-- 		(string.format("<cmd>lua require('trident').jump_to_pike('%s')<CR>", letter)),
-- 		{ noremap = true, silent = true }
-- 	)
-- end
--
-- vim.api.nvim_set_keymap("n", "tt", "", {
-- 	noremap = true,
-- 	silent = true,
-- 	callback = function()
-- 		vim.notify("Use tt<letter><type_letter> keybinds, e.g. ttct for pike c with todo", vim.log.levels.INFO)
-- 	end,
-- })
--
-- for c = string.byte("a"), string.byte("z") do
-- 	for tchar, tname in pairs(type_map) do
-- 		local letter = string.char(c)
-- 		local key = "tt" .. letter .. tchar
-- 		vim.api.nvim_set_keymap(
-- 			"n",
-- 			key,
-- 			string.format(
-- 				"<cmd>lua require('trident').add_pike({ line = vim.api.nvim_win_get_cursor(0)[1], letter = '%s', type = '%s' })<CR>",
-- 				letter,
-- 				tname
-- 			),
-- 			{ noremap = true, silent = true }
-- 		)
-- 	end
-- end
--
-- vim.api.nvim_set_keymap("n", "tr", "", {
-- 	noremap = true,
-- 	silent = true,
-- 	callback = function()
-- 		local line = vim.api.nvim_win_get_cursor(0)[1]
-- 		local filepath = vim.api.nvim_buf_get_name(0)
-- 		local pikes = require("trident.pike_manager").get_pikes_for_file(filepath)
--
-- 		for _, pike in ipairs(pikes) do
-- 			if pike.line == line then
-- 				pike.type = nil
-- 				require("trident.pike_manager").set_pikes(pikes)
-- 				require("trident.pike_ui").place_pike_signs(vim.api.nvim_get_current_buf())
-- 				require("trident").notify("Cleared type of pike '" .. pike.letter .. "' at line " .. line)
-- 				return
-- 			end
-- 		end
--
-- 		require("trident").notify("No pike found at current line", vim.log.levels.WARN)
-- 	end,
-- })
