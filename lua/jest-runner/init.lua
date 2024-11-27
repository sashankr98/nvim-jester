local Config = require("jest-runner.config")
local highlight = require("jest-runner.highlight")
local commands = require("jest-runner.commands")
local utils = require("jest-runner.utils")

local api = vim.api

local M = {}

M.setup = function(opts)
    Config.build(opts)

	if utils.is_jest_available() then
		highlight.setup()
        api.nvim_create_user_command("Jester", function(cmd_opts)
            commands.run_command(cmd_opts.fargs[1])
        end, { nargs = 1 })
	end
end

return M
