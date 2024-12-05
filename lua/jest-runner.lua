local constants = require("jest-runner.constants")
local fn = vim.fn

local M = {}

local function is_valid_jest_file(buf_name)
    vim.regex("^.*test\\.[tj]s$"):match_str(buf_name)
end

M.test_file = function()
    local file = fn.expand('%')
    if not is_valid_jest_file(file) then
        vim.print('Invalid test file')
        return
    end
    local result = vim.system({ constants.jest, file }, { text = true }):wait()
    -- TODO: Update UI
    vim.print(result.stderr..result.stdout)
end

M.setup = function()
    local jest_util_path = fn.findfile(constants.jest)
    vim.g.jest_available = jest_util_path ~= '' and true or false
end

return M
