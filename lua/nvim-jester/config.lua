--- @class Jester.Config
--- @field command string
--- @field file_patterns string[]
--- @field keywords string[]
--- @field sign_text string
--- @field sign_hl_group string

local M = {}

--- @type Jester.Config
M.defaults = {
	command = "node_modules/.bin/jest",
	file_patterns = {
		"*.test.ts",
		"*.spec.ts",
	},
	keywords = {
		"describe",
		"it",
		"test",
	},
	sign_text = "",
	sign_hl_group = "JesterDefault",
}

--- @type Jester.Config
M.config = vim.tbl_deep_extend("force", {}, M.defaults)

local validate_config = function(config)
	-- Basic type validation
	for k, v in pairs(config) do
		vim.validate({ [k] = { v, type(M.defaults[k]) } })
	end

	-- Specific validations
	if config.sign_text then
		vim.validate({
			sign_text = {
				config.sign_text,
				function(st)
					return #st <= 2
				end,
				"string of length 1-2",
			},
		})
	end
end

M.build = function(user_config)
    user_config = user_config or {}
	validate_config(user_config)

	for k, v in pairs(user_config) do
		M.config[k] = v
	end
end

return M
