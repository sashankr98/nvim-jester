local Config = require("nvim-jester.config")

local api = vim.api
local fn = vim.fn
local config = Config.config

local M = {}

M.out_writeln = function(str)
	api.nvim_out_write(str .. "\n")
end

M.err_writeln = api.nvim_err_writeln

M.is_jest_available = function()
	return fn.findfile(config.command) ~= "" and true or false
end

M.is_valid_jest_file = function(buf_name)
	return vim.regex("^.*\\.\\(test\\|spec\\)\\.ts$"):match_str(buf_name) and true or false
end

M.get_ns_id = function()
    local namespace = "Jester"
	local ns_id = api.nvim_get_namespaces()[namespace]

	if not ns_id then
		ns_id = api.nvim_create_namespace(namespace)
	end

	return ns_id
end

M.get_test_name = function(str)
    local keywords = config.keywords
	for _, kw in ipairs(keywords) do
		local _, name = string.match(str, "^.*(" .. kw .. ").*%([\"'`](.*)[\"'`].*$")
		if name ~= nil then
			return name
		end
	end
	return nil
end

return M
