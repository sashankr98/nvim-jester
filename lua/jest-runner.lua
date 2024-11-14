local constants = require("jest-runner.constants")
local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

local M = {}

local function is_valid_jest_file(buf_name)
	vim.regex("^.*test\\.[tj]s$"):match_str(buf_name)
end

M.get_test_name = function(str)
	local keywords = {
		"describe",
		"it",
		"test",
	}
	for _, kw in ipairs(keywords) do
		local _, name = string.match(str, "^.*(" .. kw .. ").*%([\"'`](.*)[\"'`].*$")
		if name ~= nil then
			return name
		end
	end
	return nil
end

M.test_file = function()
	local file = fn.expand("%")
	if not is_valid_jest_file(file) then
		vim.print("Invalid test file")
		return
	end
	local result = vim.system({ constants.jest, file }, { text = true }):wait()
	vim.print(result.stderr .. result.stdout)
end

M.get_ns_id = function()
	local ns_id = vim.b.jest_ns_id

	if not ns_id then
		ns_id = api.nvim_create_namespace(constants.namespace)
		vim.b.jest_ns_id = ns_id
	end

	return ns_id
end

M.highlight_tests = function()
	local ns_id = M.get_ns_id()
	api.nvim_buf_clear_namespace(0, ns_id, 1, -1)

	-- Possibly pass winnr and bufnr as params
	-- What does make position params do?
	lsp.buf_request(0, "textDocument/documentSymbol", lsp.util.make_position_params(0), function(err, result, _, _)
		if err then
			vim.api.nvim_err_writeln("Error when finding document symbols: " .. err.message)
			return
		end

		if not result or vim.tbl_isempty(result) then
			vim.api.nvim_out_write("No results from textDocument/documentSymbol")
			return
		end
		local locations = lsp.util.symbols_to_items(result, 0)
		local functions = {}

		for _, item in ipairs(locations) do
			if item.kind == "Function" then
				local test_name = M.get_test_name(item.text)
				if test_name then
					local extmark = api.nvim_buf_set_extmark(0, ns_id, item.lnum - 1, 0, {
						sign_text = "",
						-- Use different highlight group
						sign_hl_group = "Label",
					})
					item.text = test_name
					item.extmark = extmark
					table.insert(functions, item)
				end
			end
		end
		vim.b.fns = functions
	end)
end

-- M.highlight_tests()

M.setup = function()
	local jest_util_path = fn.findfile(constants.jest)
	vim.g.jest_available = jest_util_path ~= "" and true or false
end

return M
