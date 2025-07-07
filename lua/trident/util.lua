local M = {}

function M.hash(str)
	local sha = vim.fn.sha256 or vim.fn.sha1
	return sha(str)
end

function M.sanitize(path)
	return path:gsub("[/\\]", "_")
end

function M.shallow_copy(t)
	local copy = {}
	for i, v in ipairs(t) do
		copy[i] = v
	end
	return copy
end

return M
