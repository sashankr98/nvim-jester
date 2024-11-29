local Config = require("nvim-jester.config")
local utils = require("nvim-jester.utils")

local fn = vim.fn
local api = vim.api
local config = Config.config

local SPACE = " "

local M = {}

---@param file string
---@param test_name? string
local create_cmd = function(file, test_name)
	local cmd = {
		config.command,
		file,
	}

	if fn.findfile(config.config_path) ~= "" then
		table.insert(cmd, "--config=" .. '"' .. config.config_path .. '"')
	end
	if test_name then
		table.insert(cmd, "--testNamePattern=" .. '"' .. test_name .. '"')
	end
	if config.run_in_band then
		table.insert(cmd, "--runInBand")
	end

	return cmd
end

---@param cmd string[]
---@param title? string
local execute_cmd_in_win = function(cmd, title)
	-- Disable events while cmd is executed
	local ei = vim.o.eventignore
	vim.o.eventignore = "all"

	-- Create buffer
	local buf = api.nvim_create_buf(false, true)

	api.nvim_buf_attach(buf, false, {
		on_detach = function()
			-- Enable events after leaving cmd execution buffer
			vim.o.eventignore = ei
		end,
	})

	-- Buffer keymaps
	vim.keymap.set("n", "H", "gg", { buffer = buf })
	vim.keymap.set("n", "L", "G", { buffer = buf })
	vim.keymap.set("n", "q", ":bw<CR>", { buffer = buf })

	-- Execute cmd in buffer
	api.nvim_buf_call(buf, function()
		fn.termopen(table.concat(cmd, SPACE))
	end)

	-- Create window for buffer
	local title_padding = "  "
	local win = api.nvim_open_win(buf, true, {
		relative = "win",
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(vim.o.lines * 0.8),
		col = math.floor(vim.o.columns * 0.1),
		row = math.floor(vim.o.lines * 0.1) - 1,
		style = "minimal",
		border = "single",
		title = title_padding .. title .. title_padding,
		title_pos = "center",
	})

	-- Move cursor to the bottom of the window
	api.nvim_win_call(win, function()
		vim.cmd("$")
	end)
end

M.execute_test = function()
	if not utils.is_jest_available() then
		utils.err_writeln("Jest not available")
		return
	end

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

	local cmd = create_cmd(file, test_name)
	execute_cmd_in_win(cmd, test_name)
end

M.execute_test_buffer = function()
	if not utils.is_jest_available() then
		utils.err_writeln("Jest not available")
		return
	end

	local file = fn.expand("%")
	if not utils.is_valid_jest_file(file) then
		api.nvim_err_writeln("Invalid test file")
		return
	end

	local cmd = create_cmd(file)
	execute_cmd_in_win(cmd, file)
end

return M
