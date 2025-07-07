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
	local line = tonumber(opts.args)
	if not line or line < 1 then
		vim.notify("Invalid line number", vim.log.levels.ERROR)
		return
	end
	require("trident").add_pike({ line = line })
end, { nargs = 1 })

vim.api.nvim_create_user_command("PikeRemove", function(opts)
	local line = tonumber(opts.args)
	if not line or line < 1 then
		vim.notify("Invalid line number", vim.log.levels.ERROR)
		return
	end
	require("trident").remove_pike({ line = line })
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

vim.fn.sign_define("TridentPikeSign", { text = "♆", texthl = "WarningMsg", numhl = "" })
