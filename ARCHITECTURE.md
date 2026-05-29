# Architecture

Ajans is a Neovim plugin around local AI CLI tools. It does not implement an AI model. It manages tmux sessions, a Neovim terminal wrapper, prompt/context rendering, picker integrations, and status reporting.

## Module map

| Area | Files | Role |
| --- | --- | --- |
| Setup/config | `lua/ajans/init.lua`, `lua/ajans/config.lua` | Merge user config, create `:Ajans`, set highlights, validate options, start status hooks. |
| Commands | `lua/ajans/commands.lua` | Parse `:Ajans cli ...` commands and Lua-style args. |
| CLI API | `lua/ajans/cli/init.lua` | Public API: `select`, `show`, `toggle`, `focus`, `hide`, `close`, `send`, `prompt`, `render`. |
| Tool registry | `lua/ajans/cli/tool.lua`, `aj/cli/*.lua` | Load default tool configs from runtime path and merge user overrides. |
| State | `lua/ajans/cli/state.lua` | Combine installed tools, running sessions, attached sessions, and user filters. |
| Sessions | `lua/ajans/cli/session/init.lua`, `lua/ajans/cli/session/tmux.lua` | tmux-backed session discovery, start, attach, detach, send, submit, dump. |
| Terminal wrapper | `lua/ajans/cli/terminal.lua`, `lua/ajans/cli/scrollback.lua` | Neovim terminal window/buffer lifecycle, keymaps, send queue, mode restore, scrollback. |
| Context | `lua/ajans/cli/context/*.lua`, `lua/ajans/text.lua`, `lua/ajans/treesitter.lua` | Render prompt variables into strings with optional highlighting metadata. |
| Pickers | `lua/ajans/cli/picker/*.lua`, `lua/ajans/cli/ui/*.lua` | Tool/prompt/file/buffer selection through `vim.ui.select`, snacks, Telescope, or fzf-lua. |
| Watch | `lua/ajans/cli/watch.lua` | Watch loaded file directories and run `:checktime`. |
| Status | `lua/ajans/status.lua` | Cache attached CLI sessions for statuslines. |
| Health | `lua/ajans/health.lua` | Check Neovim version, `autoread`, tmux, process tools, and CLI executables. |
| Docs | `lua/ajans/docs.lua`, `tests/fixtures/readme.lua` | Generate reference blocks for docs. |

## Startup flow

1. User calls `require("ajans").setup(opts)`.
2. `config.setup` merges defaults with user config.
3. Ajans creates the `:Ajans` user command.
4. Scheduled setup creates state dir, highlights, autocmds, status hooks, and option validation.

## Command and API flow

```text
:Ajans cli send msg="{selection}"
        │
        ▼
lua/ajans/commands.lua parses module/command/args
        │
        ▼
require("ajans.cli").send(opts)
        │
        ▼
context renderer expands prompt variables
        │
        ▼
state layer selects/attaches a session
        │
        ▼
tool formatter adapts text for target CLI
        │
        ▼
tmux backend sends text to pane
```

## Tool loading

For each configured tool name, Ajans looks for `aj/cli/{name}.lua` on the runtime path. The runtime default and user config are deep-merged. Tool configs define command argv, process detection, URLs, key overrides, formatting, and scroll/focus behavior.

Bundled tool configs live in `aj/cli/`.

## Session model

Ajans uses tmux for all CLI sessions.

- New sessions get stable names from tool name plus cwd hash.
- Existing tmux panes are discovered with `tmux list-panes`.
- Processes are inspected with `ps`, `/proc`, and `lsof` where available.
- If Neovim is already inside tmux and `cli.mux.create` is `"window"` or `"split"`, Ajans can start an external tmux window/split instead of an embedded terminal.
- Embedded terminal sessions attach to tmux and are tracked as `terminal: ...` sessions.

## Terminal wrapper

The wrapper is a Neovim terminal buffer/window that attaches to a tmux session.

It handles:

- split/float layout
- buffer-local terminal keymaps
- terminal/normal mode restore
- delayed send queue while the CLI initializes
- cleanup on terminal close
- optional tmux scrollback capture when entering normal mode or using mouse scroll

## Context renderer

Prompt templates contain variables like `{selection}` or `{diagnostics}`. Rendering happens through `lua/ajans/cli/context/init.lua`.

Important boundary: location variables (`{file}`, `{line}`, `{position}`, `{this}` in file buffers) render file references, not whole file contents. Text content comes from `{selection}` or custom context providers.

## Watch and reload

When enabled, file watching starts when a CLI terminal starts and stops when all Ajans terminals close. Ajans watches directories for loaded file buffers, records changed paths, and runs `:checktime`. Neovim `autoread` controls automatic reload behavior.

## Events and status

Session attach/detach emits user autocmds:

- `User AjansCliAttach`
- `User AjansCliDetach`

`lua/ajans/status.lua` listens to those events and exposes `require("ajans.status").cli()` for statusline integrations.

## Boundaries

- No hosted service dependency.
- No bundled AI model.
- No non-tmux session backend.
- No automatic whole-file context unless you add custom context.
