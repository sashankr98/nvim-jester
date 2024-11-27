local Config = require("jest-runner.config")
local highlight = require("jest-runner.highlight")
local commands = require("jest-runner.commands")
local utils = require("jest-runner.utils")

local api = vim.api

local M = {}

local complete = function (arglead, line)
    local words = vim.split(line, '%s+')

    local matches = {}
    if #words == 2 then
        for k, _ in pairs(commands.command_functions) do
            if vim.startswith(k, arglead) then
                table.insert(matches, k)
            end
        end
    end

    return matches
end

M.setup = function(opts)
    Config.build(opts)

	if utils.is_jest_available() then
		highlight.setup()
        api.nvim_create_user_command("Jester",
            function(cmd_opts)
                commands.run_command(cmd_opts.fargs[1])
            end,
            {
                nargs = 1,
                complete = complete,
            })
	end
end

return M
