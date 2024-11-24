local constants = require("jest-runner.constants")
local utils = require("jest-runner.utils")

local fn = vim.fn
local api = vim.api

local M = {}

M.execute_test = function()
    local file = fn.expand("%")
    if not utils.is_valid_jest_file(file) then
        utils.err_writeln("Invalid test file")
        return
    end

    local current_line = api.nvim_get_current_line()
    local test_name = utils.get_test_name(current_line)
    if not test_name then
        utils.err_writeln("No valid test\n")
        return
    end

    local cmd = {
        constants.jest_path,
        file,
        "--testNamePattern=" .. test_name,
    }
    local result = vim.system(cmd, { text = true }):wait()
    vim.print(result.stderr .. result.stdout)
end

M.execute_test_file = function()
    local file = fn.expand("%")
    if not utils.is_valid_jest_file(file) then
        api.nvim_err_writeln("Invalid test file")
        return
    end
    local result = vim.system({ constants.jest_path, file }, { text = true }):wait()
    vim.print(result.stderr .. result.stdout)
end

return M
