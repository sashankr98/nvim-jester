local constants = require("jest-runner.constants")
local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

local M = {}

local function is_valid_jest_file(buf_name)
	vim.regex("^.*test\\.[tj]s$"):match_str(buf_name)
end

local AUGROUP = "JesterCommands"
local TESTS = "tests"
local TEXT_DOC_SYMBOL_METHOD = "textDocument/documentSymbol"

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
	local ns_id = vim.g.jest_ns_id

	if not ns_id then
		ns_id = api.nvim_create_namespace(constants.name)
		vim.g.jest_ns_id = ns_id
	end

	return ns_id
end

M.highlight_tests = function(bufnr)
	local ns_id = M.get_ns_id()
	api.nvim_buf_clear_namespace(bufnr, ns_id, 1, -1)

    -- Find any client that supports textDocument/documentSymbol 
    local client = lsp.get_clients({
        bufnr = bufnr,
        method = TEXT_DOC_SYMBOL_METHOD,
    })[1]

    if not client then
        api.nvim_out_write("No valid client")
        return
    end
    local handler = function (err, result, _, _)
		if err then
			vim.api.nvim_err_writeln("Error when finding document symbols: " .. err.message)
			return
		end

		if not result or vim.tbl_isempty(result) then
			vim.api.nvim_out_write("No results from textDocument/documentSymbol")
			return
		end
		local locations = lsp.util.symbols_to_items(result, bufnr)
		local tests = {}

		for _, item in ipairs(locations) do
			if item.kind == "Function" then
				local test_name = M.get_test_name(item.text)
				if test_name then
					local extmark = api.nvim_buf_set_extmark(bufnr, ns_id, item.lnum - 1, 0, {
						sign_text = "",
						-- Use different highlight group
						sign_hl_group = "Label",
					})
					item.text = test_name
					item.extmark = extmark
					table.insert(tests, item)
				end
			end
		end
        -- TODO: Ensure highlight is executed only once
        if vim.b.hl_count == nil then
            vim.b.hl_count = 1
        else
            vim.b.hl_count = vim.b.hl_count + 1
        end
        api.nvim_buf_set_var(bufnr, TESTS, tests)
    end

	-- Possibly pass winnr and bufnr as params
    client.request(TEXT_DOC_SYMBOL_METHOD, lsp.util.make_position_params(), handler, bufnr)
end

M.is_jest_available = function()
	return fn.findfile(constants.jest) ~= "" and true or false
end

local setup_autocommands = function()
	api.nvim_create_augroup(AUGROUP, { clear = true })

	local test_file_pattern = { "*.test.ts" }

	api.nvim_create_autocmd({ "BufReadPost", "LspAttach" }, {
		group = AUGROUP,
		pattern = test_file_pattern,
		once = false,
		callback = function(ev)
            vim.schedule(function ()
                if vim.b.tests == nil then
                    M.highlight_tests(ev.buf)
                end
            end)
		end,
	})
end

M.setup = function()
	if  M.is_jest_available() then
        setup_autocommands()
	end
end

return M
