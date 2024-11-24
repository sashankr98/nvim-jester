local constants = require("jest-runner.constants")
local utils = require("jest-runner.utils")

local lsp = vim.lsp
local api = vim.api

local TESTS_KEY = "tests"
local TEXT_DOC_SYMBOL_METHOD = "textDocument/documentSymbol"

local M = {}

M.highlight_tests = function(lsp_client, bufnr)
    local ns_id = utils.get_ns_id()
    api.nvim_buf_clear_namespace(bufnr, ns_id, 1, -1)

    local response = lsp_client.request_sync(TEXT_DOC_SYMBOL_METHOD, lsp.util.make_position_params(), 2000, bufnr)

    if not response or response.err then
        vim.api.nvim_err_writeln("Error when finding document symbols: " .. response.err.message)
        return
    end

    if not response.result or vim.tbl_isempty(response.result) then
        vim.api.nvim_out_write("No results from textDocument/documentSymbol")
        return
    end

    local symbols = response.result
    local items = lsp.util.symbols_to_items(symbols, bufnr)
    local tests = {}

    for _, item in ipairs(items) do
        if item.kind == "Function" then
            local test_name = utils.get_test_name(item.text)
            if test_name then
                local extmark = api.nvim_buf_set_extmark(bufnr, ns_id, item.lnum - 1, 0, {
                    sign_text = "",
                    -- TODO: Use different highlight group
                    sign_hl_group = "Label",
                })
                item.text = test_name
                item.extmark = extmark
                table.insert(tests, item)
            end
        end
    end
    api.nvim_buf_set_var(bufnr, TESTS_KEY, tests)
end

M.setup_autocommands = function()
    api.nvim_create_augroup(constants.augroup, { clear = true })

    local test_file_patterns = {
        "*.test.ts",
        "*.spec.ts",
    }

    api.nvim_create_autocmd({ "LspAttach" }, {
        group = constants.augroup,
        pattern = test_file_patterns,
        callback = function(event)
            local tests_found = pcall(api.nvim_buf_get_var, event.buf, TESTS_KEY)
            if tests_found then
                return
            end

            local client = lsp.get_client_by_id(event.data.client_id)
            if not client or not client.supports_method(TEXT_DOC_SYMBOL_METHOD) then
                return
            end

            M.highlight_tests(client, event.buf)
        end,
    })

    api.nvim_create_autocmd({ "TextChanged" }, {
        group = constants.augroup,
        pattern = test_file_patterns,
        callback = function(event)
            -- Find the first valid lsp client
            local client = lsp.get_clients({ method = TEXT_DOC_SYMBOL_METHOD })[1]
            if not client then
                return
            end

            M.highlight_tests(client, event.buf)
        end,
    })
end

return M
