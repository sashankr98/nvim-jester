local constants = require("jest-runner.constants")
local utils = require("jest-runner.utils")

local fn  = vim.fn

local M = {}

M.test_file = function()
    local file = fn.expand("%")
    if not utils.is_valid_jest_file(file) then
        vim.print("Invalid test file")
        return
    end
    local result = vim.system({ constants.jest_path, file }, { text = true }):wait()
    vim.print(result.stderr .. result.stdout)
end

return M
