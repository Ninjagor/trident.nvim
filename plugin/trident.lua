vim.api.nvim_create_user_command("TridentAdd", function(opts)
	require("trident").add(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("TridentRemove", function(opts)
	require("trident").remove(opts.args)
end, { nargs = "?" })

-- vim.api.nvim_create_user_command("TridentList", function()
-- 	local marks = require("trident").get_all()
-- 	print(vim.inspect(marks))
-- end, {})

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
