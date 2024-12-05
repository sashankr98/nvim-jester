# nvim-jester
Neovim plugin to execute individual JS/TS tests with jest

## Features

- Navigation between tests
- Signs for tests
- Execute individual test or all tests in buffer

## Requirements

This plugin was developed and tested using:

- Neovim: v0.10.0
- jest-cli: v29.7.0

## Installation

Install using a package manager of your choice such as [lazy.nvim](https://github.com/folke/lazy.nvim)


```lua
{
    "sashankr98/nvim-jester",
    opts = {
        command = "npx jest",
    },
}
```

## Usage

To use the default configuraton, run:

```lua
require("nvim-jester").setup()
```

Configuration can be passed to the setup function. Here is an example with most of
the default settings:

```lua
require("nvim-jester").setup({
  command = "node_modules/.bin/jest", -- Jest CLI to use. Also accepts "npx jest"
  config_path = "jest.config.ts", -- Path to jest config
  run_in_band = true -- Sets the --runInBand option when executing tests. https://jestjs.io/docs/cli#--runinband
  file_patterns = { -- Test highlighting and execution will be supported for these file patterns
    "*.test.ts",
    "*.spec.ts",
  },
  keywords = { -- Tests defined with these keywords will be highlighted
    "describe",
    "it",
    "test",
  },
  sign_text = "", -- Used to set extmark signs for tests
  sign_hl_group = "JesterDefault", -- Used to highlight sign_text
})
```

## Vim Commands

All `nvim-jester` functions are accessible with the `:Jester` command followed by the appropriate subcommand:

- `next_test`: Moves cursor to the next test in the buffer that matches one of the provided keywords.
- `previous_test`: Moves cursor to the previous test in the buffer that matches one of the provided keywords.
- `execute_test`: Executes the current test under the cursor in a new terminal buffer.
- `execute_test_buffer`: Execute all tests in the current buffer in a new terminal buffer.

Example:

```viml
" Navigate to the next test
:Jester next_test

" Execute test under cursor
:Jester execute_test

" Execute all tests in buffer
:Jester execute_test_buffer
```

## TODOs

- Add support for other cli options.
- Support passing cli options to the "execute_test" commands.
- Support test debugging
