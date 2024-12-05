local constants = require("jest-runner.constants")
local api = vim.api
local fn = vim.fn

local M = {}

local get_test_name = function (str)
    for _, kw in ipairs(constants.keywords) do
        local _, name = string.match(str, "^.*("..kw..").*%([\"'`](.*)[\"'`].*$")
        if (name ~= nil) then
            return name
        end
    end
    return nil
end

M.extract_tests = function()
	local line_count = fn.line("$")
    local lines = api.nvim_buf_get_lines(0, 0, line_count-1, false)
    local tests = {}

    for _,line in ipairs(lines) do
        local test_name = get_test_name(line)
        if (test_name ~= nil) then
            table.insert(tests, test_name)
        end
    end
    vim.print(tests)
end

-- TODO
-- 1. Add extmarks for each test
-- 2. Add command to move cursor to next/prev test
-- 3. Add command to execute test at extmark
-- 4. Create suitable UI for test output. Terminal? Scratch buffer? How do colours work?
return M
