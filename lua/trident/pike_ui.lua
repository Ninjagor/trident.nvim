local M = {}

function M.place_pike_signs(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local pikes = require("trident.pike_manager").get_pikes_for_file(filepath)

	vim.fn.sign_unplace("trident_pikes", { buffer = bufnr })

	local ns = vim.api.nvim_create_namespace("trident_pikes_virtualtext")
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	for i, pike in ipairs(pikes) do
		vim.fn.sign_place(i, "trident_pikes", "TridentPikeSign", bufnr, { lnum = pike.line, priority = 10 })

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
				virt_text = { { " ** " .. pike_type_caps .. " ** ", "TridentPikeVirtualText" } },
				virt_text_pos = "eol",
				hl_mode = "combine",
			})
		end
	end
end

return M
