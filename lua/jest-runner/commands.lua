local highlight = require("jest-runner.highlight")
local tester = require("jest-runner.tester")
local utils = require("jest-runner.utils")

local M = {}

--- @type table<string, function>
M.command_functions = {
    previous_test = highlight.previous_test,
    next_test = highlight.next_test,
    execute_test = tester.execute_test,
    execute_test_file = tester.execute_test_file,
}

M.run_command = function (cmd)
    if not cmd then
        return
    end

    local fn = M.command_functions[cmd]
    if not fn then
        utils.err_writeln("Invalid command")
    end
    fn()
end

return M
