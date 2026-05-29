# ajans.nvim

Neovim sidecar for AI CLI tools.

`ajans.nvim` is a simplified fork of [sidekick.nvim](https://github.com/folke/sidekick.nvim). It keeps the scope narrow: run local AI CLIs from Neovim, send editor context, and keep sessions alive with tmux.

## What it does

- Opens supported AI CLI tools in a Neovim terminal wrapper.
- Reuses tmux sessions so CLI work survives window changes and Neovim restarts.
- Sends verified editor context: file locations, cursor/range positions, selections, diagnostics, quickfix entries, buffers, functions, and classes.
- Provides prompt, tool, file, and buffer pickers.
- Watches loaded file directories and runs `:checktime` after external changes; enable `autoread` for automatic reloads.
- Exposes small Lua APIs for keymaps, picker integrations, and statuslines.

## Requirements

- Neovim `>= 0.11.2`
- [tmux](https://github.com/tmux/tmux/wiki)
- One or more AI CLI tools, such as Claude, Codex, Copilot, Antigravity, Opencode, or Qwen
- Optional: [snacks.nvim](https://github.com/folke/snacks.nvim), Telescope, or fzf-lua for picker workflows
- Optional: [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) for `{function}` and `{class}` context
- Optional on Unix-like systems: `ps` and `lsof` for running-session discovery

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "assagman/ajans.nvim",
  opts = {},
}
```

Then run:

```vim
:checkhealth ajans
```

Add your preferred mappings from [KEYMAPS.md](./KEYMAPS.md).

## Quick start

```vim
:Ajans cli select
:Ajans cli toggle
:Ajans cli send msg="{this}"
:Ajans cli prompt
```

Common Lua calls:

```lua
require("ajans.cli").select()
require("ajans.cli").toggle()
require("ajans.cli").send({ msg = "{selection}" })
require("ajans.cli").prompt()
```

Use `{selection}` when you want to send selected code. Use `{file}`, `{line}`, `{position}`, or `{this}` when you want to send location context.

## Supported CLI tools

Ajans ships default configs for:

`aider`, `amazon_q`, `antigravity`, `claude`, `codex`, `copilot`, `crush`, `cursor`, `grok`, `opencode`, `pi`, and `qwen`.

Run `:checkhealth ajans` to see which tools are installed.

## Documentation

- [USAGE.md](./USAGE.md) — commands, prompts, context variables, pickers, statusline, troubleshooting
- [CONFIG.md](./CONFIG.md) — setup options, tool config, custom prompts, custom context
- [KEYMAPS.md](./KEYMAPS.md) — suggested user mappings and default terminal mappings
- [ARCHITECTURE.md](./ARCHITECTURE.md) — internals and data flow
- [DEVELOPMENT.md](./DEVELOPMENT.md) — contributor workflow and validation

## Scope

Ajans is not an AI model, completion engine, or hosted agent service. It connects Neovim to local CLI tools you install and configure.
