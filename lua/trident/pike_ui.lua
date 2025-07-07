local M = {}

function M.place_pike_signs(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local pikes = require("trident.pike_manager").get_pikes_for_file(filepath)

	vim.fn.sign_unplace("trident_pikes", { buffer = bufnr })

	for i, pike in ipairs(pikes) do
		vim.fn.sign_place(i, "trident_pikes", "TridentPikeSign", bufnr, { lnum = pike.line, priority = 10 })
	end
end

return M
