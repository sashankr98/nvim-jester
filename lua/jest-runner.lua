local highlight = require("jest-runner.highlight")
local utils = require("jest-runner.utils")

local M = {}

M.setup = function()
    if utils.is_jest_available() then
        highlight.setup_autocommands()
    end
end

return M
