local Config = require("nvim-jester.config")
local utils = require("nvim-jester.utils")

local lsp = vim.lsp
local api = vim.api
local config = Config.config

local TESTS_KEY = "tests"
local TEXT_DOC_SYMBOL_METHOD = "textDocument/documentSymbol"

local M = {}

---@param lsp_client vim.lsp.Client
---@param bufnr number
local highlight_tests = function(lsp_client, bufnr)

	local response = lsp_client.request_sync(TEXT_DOC_SYMBOL_METHOD, lsp.util.make_position_params(), 2000, bufnr)

	if not response or response.err then
		utils.err_writeln("Error when finding document symbols: " .. response.err.message)
		return
	end

	if not response.result or vim.tbl_isempty(response.result) then
		utils.out_writeln("No results from textDocument/documentSymbol")
		return
	end

	local symbols = response.result
	local items = lsp.util.symbols_to_items(symbols, bufnr)
	local tests = {}

	local ns_id = utils.get_ns_id()
	api.nvim_buf_clear_namespace(bufnr, ns_id, 1, -1)

	for _, item in ipairs(items) do
		if item.kind == "Function" then
			local test_name = utils.get_test_name(item.text)
			if test_name then
				api.nvim_buf_set_extmark(bufnr, ns_id, item.lnum - 1, 0, {
					sign_text = config.sign_text,
					sign_hl_group = config.sign_hl_group,
				})
				table.insert(tests, item)
			end
		end
	end
	api.nvim_buf_set_var(bufnr, TESTS_KEY, tests)
end

M.setup = function()
    api.nvim_set_hl(0, Config.defaults.sign_hl_group, { fg = "#72BF6A" })

	local augroup = "Jester"
	api.nvim_create_augroup(augroup, { clear = true })

	api.nvim_create_autocmd({ "LspAttach" }, {
		group = augroup,
		pattern = config.file_patterns,
		callback = function(event)
			local tests_highlighted = pcall(api.nvim_buf_get_var, event.buf, TESTS_KEY)
			if tests_highlighted then
				return
			end

			local client = lsp.get_client_by_id(event.data.client_id)
			if not client or not client.supports_method(TEXT_DOC_SYMBOL_METHOD) then
				return
			end

			highlight_tests(client, event.buf)
		end,
	})

	api.nvim_create_autocmd({ "TextChanged" }, {
		group = augroup,
		pattern = config.file_patterns,
		callback = function(event)
			-- Find the first valid lsp client
			local client = lsp.get_clients({ method = TEXT_DOC_SYMBOL_METHOD })[1]
			if not client then
				return
			end

			highlight_tests(client, event.buf)
		end,
	})

end

---@param target 'next' | 'previous'
local navigate_to_test = function(target)
	local tests_highlighted = pcall(api.nvim_buf_get_var, 0, TESTS_KEY)
	if not tests_highlighted then
		utils.out_writeln("No tests")
		return
	end

	local current_row = api.nvim_win_get_cursor(0)[1] - 1

	local ns_id = utils.get_ns_id()

	local end_row
	if target == "next" then
		end_row = -1
	elseif target == "previous" then
		end_row = 0
	end
	local extmarks = api.nvim_buf_get_extmarks(0, ns_id, { current_row, 0 }, end_row, {})

	local destination_row
	if extmarks[1] and extmarks[1][2] ~= current_row then
		destination_row = extmarks[1][2]
	elseif extmarks[2] then
		destination_row = extmarks[2][2]
	end

	if not destination_row then
		utils.out_writeln("No " .. target .. " test")
		return
	end

	api.nvim_win_set_cursor(0, { destination_row + 1, 0 })
end

M.next_test = function()
	navigate_to_test("next")
end

M.previous_test = function()
	navigate_to_test("previous")
end

return M
