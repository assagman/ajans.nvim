# 🤖 `ajans.nvim`

**ajans.nvim** is your Neovim AI ajans for working with AI CLI tools
without leaving your editor. Chat with assistants, send rich buffer context,
and keep sessions alive inside your normal Neovim workflow.

<img width="2311" height="1396" alt="image" src="https://github.com/user-attachments/assets/63a33610-9a8e-45e2-bbd0-b7e3a4fde621" />

## ✨ Features

- **💬 Integrated AI CLI Terminal**
  - 🚀 **Direct Access to AI CLIs**: Interact with your favorite AI command-line tools without leaving Neovim.
  - 📦 **Pre-configured for Popular Tools**: Out-of-the-box support for Claude, Antigravity, Grok, Codex, Copilot CLI, and more.
  - ✨ **Context-Aware Prompts**: Automatically include file content, cursor position, and diagnostics in your prompts.
  - 📝 **Prompt Library**: A library of pre-defined prompts for common tasks like explaining code, fixing issues, or writing tests.
  - 🔄 **Session Persistence**: Keep your CLI sessions alive with `tmux` integration.
  - 📂 **Automatic File Watching**: Automatically reloads files in Neovim when they are modified by AI tools.

- **🔌 Extensible and Customizable**
  - ⚙️ **Flexible Configuration**: Fine-tune every aspect of the plugin to your liking.
  - 🧩 **Plugin-Friendly API**: A rich API for integrating with other plugins and building custom workflows.
  - 🎨 **Customizable UI**: Change terminal layout, keymaps, picker actions, and statusline output.

## 📋 Requirements

- **Neovim** `>= 0.11.2` or newer
- [snacks.nvim](https://github.com/folke/snacks.nvim) for better prompt/tool selection **_(optional)_**
- [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) **_(`main` branch)_** for `{function}` and `{class}` context variables **_(optional)_**
- [tmux](https://github.com/tmux/tmux/wiki) for persistent CLI sessions
- AI cli tools, such as Codex, Claude, Copilot, Antigravity, … **_(optional)_**
  see the [🤖 AI CLI Integration](#-ai-cli-integration) section for details.
- [lsof](https://man7.org/linux/man-pages/man8/lsof.8.html) and [ps](https://man7.org/linux/man-pages/man1/ps.1.html) are used
  on Unix-like systems to detect running AI CLI tool sessions. **_(optional, but recommended)_**

## 🚀 Quick Start

1. **Install** the plugin with your package manager (see below)
2. **Check health**: `:checkhealth ajans`
3. **Install at least one AI CLI tool** such as Claude, Codex, Antigravity, or Copilot CLI
4. **Try it out**:
   - Use `<leader>aa` to open your current AI CLI session
   - Use `<leader>as` to select a specific tool
   - Use `<leader>at`, `<leader>af`, or `<leader>av` to send context

## 📦 Installation

Install with your favorite manager. With [lazy.nvim](https://github.com/folke/lazy.nvim):

<!-- setup_base:start -->

```lua
{
  "assagman/ajans.nvim",
  opts = {
    -- add any options here
  },
  keys = {
    {
      "<c-.>",
      function() require("ajans.cli").focus() end,
      desc = "Ajans Focus",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function() require("ajans.cli").toggle() end,
      desc = "Ajans Toggle CLI",
    },
    {
      "<leader>as",
      function() require("ajans.cli").select() end,
      -- Or to select only installed tools:
      -- require("ajans.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function() require("ajans.cli").close() end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function() require("ajans.cli").send({ msg = "{this}" }) end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function() require("ajans.cli").send({ msg = "{file}" }) end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function() require("ajans.cli").send({ msg = "{selection}" }) end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function() require("ajans.cli").prompt() end,
      mode = { "n", "x" },
      desc = "Ajans Select Prompt",
    },
    -- Example of a keybinding to open Claude directly
    {
      "<leader>ac",
      function() require("ajans.cli").toggle({ name = "claude", focus = true }) end,
      desc = "Ajans Toggle Claude",
    },
  },
}
```

<!-- setup_base:end -->

> [!TIP]
> It's a good idea to run `:checkhealth ajans` after install.



## ⚙️ Configuration

The module ships with safe defaults and exposes everything through
`require("ajans").setup({ ... })`.

<details>
<summary>Default settings</summary>

<!-- config:start -->

```lua
---@class ajans.Config
local defaults = {
  -- Work with AI cli tools directly from within Neovim
  cli = {
    watch = true, -- notify Neovim of file changes done by AI CLI tools
    ---@class ajans.win.Opts
    win = {
      --- This is run when a new terminal is created, before starting it.
      --- Here you can change window options `terminal.opts`.
      ---@param terminal ajans.cli.Terminal
      config = function(terminal) end,
      wo = {}, ---@type vim.wo
      bo = {}, ---@type vim.bo
      layout = "right", ---@type "float"|"left"|"bottom"|"top"|"right"
      --- Options used when layout is "float"
      ---@type vim.api.keyset.win_config
      float = {
        width = 0.9,
        height = 0.9,
      },
      -- Options used when layout is "left"|"bottom"|"top"|"right"
      ---@type vim.api.keyset.win_config
      split = {
        width = 80, -- set to 0 for default split width
        height = 20, -- set to 0 for default split height
      },
      --- CLI Tool Keymaps (default mode is `t`)
      ---@type table<string, ajans.cli.Keymap|false>
      keys = {
        buffers       = { "<c-b>", "buffers"   , mode = "nt", desc = "open buffer picker" },
        files         = { "<c-f>", "files"     , mode = "nt", desc = "open file picker" },
        hide_n        = { "q"    , "hide"      , mode = "n" , desc = "hide the terminal window" },
        hide_ctrl_q   = { "<c-q>", "hide"      , mode = "n" , desc = "hide the terminal window" },
        hide_ctrl_dot = { "<c-.>", "hide"      , mode = "nt", desc = "hide the terminal window" },
        hide_ctrl_z   = { "<c-z>", "blur"      , mode = "nt", desc = "go back to the previous window without hiding the terminal" },
        prompt        = { "<c-p>", "prompt"    , mode = "t" , desc = "insert prompt or context" },
        stopinsert    = { "<c-q>", "stopinsert", mode = "t" , desc = "enter normal mode" },
        normal_cr     = { "<cr>" , "insert_cr" , mode = "n" , desc = "send <cr> to the terminal and enter terminal mode" },
        -- Navigate windows in terminal mode. Only active when:
        -- * layout is not "float"
        -- * there is another window in the direction
        -- With the default layout of "right", only `<c-h>` will be mapped
        nav_left      = { "<c-h>", "nav_left"  , expr = true, desc = "navigate to the left window" },
        nav_down      = { "<c-j>", "nav_down"  , expr = true, desc = "navigate to the below window" },
        nav_up        = { "<c-k>", "nav_up"    , expr = true, desc = "navigate to the above window" },
        nav_right     = { "<c-l>", "nav_right" , expr = true, desc = "navigate to the right window" },
      },
      ---@type fun(dir:"h"|"j"|"k"|"l")?
      --- Function that handles navigation between windows.
      --- Defaults to `vim.cmd.wincmd`. Used by the `nav_*` keymaps.
      nav = nil,
    },
    ---@class ajans.cli.Mux
    mux = {
      -- terminal: tmux sessions will be attached inside a Neovim terminal
      -- window: when run inside tmux, new sessions will be created in a new window
      -- split: when run inside tmux, new sessions will be created in a new split
      create = "split", ---@type "terminal"|"window"|"split"
      split = {
        vertical = true, -- vertical or horizontal split
        size = 0.5, -- size of the split (0-1 for percentage)
      },
      -- max lines to capture when dumping a multiplexer pane for scrollback support
      -- more lines means slower loading of the scrollback
      dump = 2000,
    },
    --- Actual cli tool config is loaded from the runtime path `aj/cli/{tool}.lua` and merged with the config below.
    --- For default configs, see https://github.com/assagman/ajans.nvim/tree/main/aj/cli
    ---@type table<string, ajans.cli.Config|{}>
    tools = {
      aider    = {},
      amazon_q = {},
      claude   = {},
      codex    = {},
      copilot  = {},
      crush    = {},
      cursor   = {},
      antigravity = {},
      grok     = {},
      opencode = {},
      pi       = {},
      qwen     = {},
    },
    --- Add custom context. See `lua/ajans/cli/context/init.lua`
    ---@type table<string, ajans.context.Fn>
    context = {},
    ---@type table<string, ajans.Prompt|string|fun(ctx:ajans.context.ctx):(string?)>
    prompts = {
      changes         = "Can you review my changes?",
      diagnostics     = "Can you help me fix the diagnostics in {file}?\n{diagnostics}",
      diagnostics_all = "Can you help me fix these diagnostics?\n{diagnostics_all}",
      document        = "Add documentation to {function|line}",
      explain         = "Explain {this}",
      fix             = "Can you fix {this}?",
      optimize        = "How can {this} be optimized?",
      review          = "Can you review {file} for any issues or improvements?",
      tests           = "Can you write tests for {this}?",
      -- simple context prompts
      buffers         = "{buffers}",
      file            = "{file}",
      line            = "{line}",
      position        = "{position}",
      quickfix        = "{quickfix}",
      selection       = "{selection}",
      ["function"]    = "{function}",
      class           = "{class}",
    },
    -- preferred picker for selecting files
    ---@alias ajans.picker "snacks"|"telescope"|"fzf-lua"
    picker = "snacks", ---@type ajans.picker
  },
  ui = {
    icons = {
      attached          = " ",
      started           = " ",
      installed         = " ",
      missing           = " ",
      external_attached = "󰖩 ",
      external_started  = "󰖪 ",
      terminal_attached = " ",
      terminal_started  = " ",
    },
  },
}
```

<!-- config:end -->

</details>

## 🤖 AI CLI Integration

Ajans runs local AI CLI tools through tmux so sessions persist across Neovim
windows and restarts. When needed, Ajans opens a lightweight Neovim terminal
wrapper that attaches to the tmux session while helper prompts bundle buffer
context, the current cursor position, and diagnostics.

<!-- api_cli:start -->

<table><tr><th>Cmd</th><th>Lua</th></tr>
<tr><td><code>:Ajans cli close</code> </td><td>


```lua
---@param opts? ajans.cli.Hide
---@overload fun(name: string)
require("ajans.cli").close(opts)
```

</td></tr>
<tr><td><code>:Ajans cli focus</code> Toggle focus of the terminal window if it is already open</td><td>


```lua
---@param opts? ajans.cli.Show
---@overload fun(name: string)
require("ajans.cli").focus(opts)
```

</td></tr>
<tr><td><code>:Ajans cli hide</code> </td><td>


```lua
---@param opts? ajans.cli.Hide
---@overload fun(name: string)
require("ajans.cli").hide(opts)
```

</td></tr>
<tr><td><code>:Ajans cli prompt</code> Select a prompt to send</td><td>


```lua
---@param opts? ajans.cli.Prompt|{cb:nil}
---@overload fun(cb:fun(msg?:string))
require("ajans.cli").prompt(opts)
```

</td></tr>
<tr><td> Render a message template or prompt</td><td>


```lua
---@param opts? ajans.cli.Message|string
require("ajans.cli").render(opts)
```

</td></tr>
<tr><td><code>:Ajans cli select</code> Start or attach to a CLI tool</td><td>


```lua
---@param opts? ajans.cli.Select|{cb:nil}|{focus?:boolean}
---@overload fun(cb:fun(state?:ajans.cli.State))
require("ajans.cli").select(opts)
```

</td></tr>
<tr><td><code>:Ajans cli send</code> Send a message or prompt to a CLI</td><td>


```lua
---@param opts? ajans.cli.Send
---@overload fun(msg:string)
require("ajans.cli").send(opts)
```

</td></tr>
<tr><td><code>:Ajans cli show</code> </td><td>


```lua
---@param opts? ajans.cli.Show
---@overload fun(name: string)
require("ajans.cli").show(opts)
```

</td></tr>
<tr><td><code>:Ajans cli toggle</code> </td><td>


```lua
---@param opts? ajans.cli.Show
---@overload fun(name: string)
require("ajans.cli").toggle(opts)
```

</td></tr>
</table>

<!-- api_cli:end -->

### Prompts & Context

Ajans comes with a set of predefined prompts that you can use with your AI tools.
You can also use context variables in your prompts to include information about the
current file, selection, diagnostics, and more.

<img width="1431" height="723" alt="image" src="https://github.com/user-attachments/assets/652867ec-f34e-4036-9b0b-8a4817cc8722" />

<details><summary><strong>Available Prompts</strong></summary>

- **changes**: `Can you review my changes?`
- **diagnostics**: `Can you help me fix the diagnostics in {file}?\n{diagnostics}`
- **diagnostics_all**: `Can you help me fix these diagnostics?\n{diagnostics_all}`
- **document**: `Add documentation to {function|line}`
- **explain**: `Explain {this}`
- **fix**: `Can you fix {this}?`
- **optimize**: `How can {this} be optimized?`
- **review**: `Can you review {file} for any issues or improvements?`
- **tests**: `Can you write tests for {this}?`

</details>

<details><summary><strong>Available Context Variables</strong></summary>

- `{buffers}`: A list of all open buffers.
- `{file}`: The current file path.
- `{position}`: The cursor position in the current file.
- `{line}`: The current line.
- `{selection}`: The visual selection.
- `{diagnostics}`: The diagnostics for the current buffer.
- `{diagnostics_all}`: All diagnostics in the workspace.
- `{quickfix}`: The current quickfix list, including title and formatted items.
- `{function}`: The function at cursor (Tree-sitter) - returns location like `function foo @file:10:5`.
- `{class}`: The class/struct at cursor (Tree-sitter) - returns location.
- `{this}`: A special context variable. If the current buffer is a file, it resolves to `{position}`. Otherwise, it resolves to the literal string "this" and appends the current `{selection}` to the prompt.

</details>

### Snacks.nvim Picker Integration

If you're using [snacks.nvim](https://github.com/folke/snacks.nvim), you can send picker selections directly to Ajans's AI CLI tools. This is useful for sending search results, grep matches, or file selections as context.

<details><summary>Example Snacks picker configuration</summary>

<!-- snacks_picker:start -->

```lua
{
  "folke/snacks.nvim",
  optional = true,
  opts = {
    picker = {
      actions = {
        ajans_send = function(...)
          return require("ajans.cli.picker.snacks").send(...)
        end,
      },
      win = {
        input = {
          keys = {
            ["<a-a>"] = {
              "ajans_send",
              mode = { "n", "i" },
            },
          },
        },
      },
    },
  },
}
```

<!-- snacks_picker:end -->

With this configuration, pressing `<a-a>` in any Snacks picker will send the selected items to your current AI CLI session. The integration automatically handles:

- File selections with full paths
- Grep results with line numbers and positions
- Multiple selections (sends all selected items)
- Position ranges for precise context

</details>

### CLI Keymaps

You can customize the keymaps for the CLI window by setting the `cli.win.keys` option.
The default keymaps are:

- `q` (in normal mode): Hide the terminal window.
- `<c-q>` (in terminal mode): Hide the terminal window.
- `<c-z>`: Leave the CLI window.
- `<c-p>`: Insert prompt or context.

<details><summary>Example of how to override the default keymaps
</summary>

```lua
{
  "assagman/ajans.nvim",
  opts = {
    cli = {
      win = {
        keys = {
          -- override the default hide keymap
          hide_n = { "<leader>q", "hide", mode = "n" },
          -- add a new keymap to say hi
          say_hi = {
            "<c-h>",
            function(t)
              t:send("hi!")
            end,
          },
        },
      },
    },
  },
}
```

</details>

### Default CLI tools

Ajans preconfigures popular AI CLIs. Run `:checkhealth ajans` to see which ones are installed.

| Tool                                                        | Description          | Installation                                                                                                           |
| ----------------------------------------------------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [`aider`](https://github.com/Aider-AI/aider)                | AI pair programmer   | `pip install aider-chat` or `pipx install aider-chat`                                                                  |
| [`amazon_q`](https://github.com/aws/amazon-q-developer-cli) | Amazon Q Developer   | [Install guide](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-getting-started-installing.html) |
| [`claude`](https://github.com/anthropics/claude-code)       | Claude Code CLI      | [See Claude Code docs](https://code.claude.com/docs/en/overview#get-started)
| [`codex`](https://github.com/openai/codex)                  | OpenAI Codex CLI     | See [OpenAI docs](https://github.com/openai/codex)                                                                     |
| [`copilot`](https://github.com/github/copilot-cli)          | GitHub Copilot CLI   | `npm install -g @githubnext/github-copilot-cli`                                                                        |
| [`crush`](https://github.com/charmbracelet/crush)           | Charm's AI assistant | See [installation](https://github.com/charmbracelet/crush)                                                             |
| [`cursor`](https://cursor.com/cli)                          | Cursor CLI agent     | See [Cursor docs](https://cursor.com/cli)                                                                              |
| [`antigravity`](https://github.com/google-deepmind/antigravity-cli) | Antigravity CLI      | See [repo](https://github.com/google-deepmind/antigravity-cli)                                                         |
| [`grok`](https://github.com/superagent-ai/grok-cli)         | xAI Grok CLI         | See [repo](https://github.com/superagent-ai/grok-cli)                                                                  |
| [`opencode`](https://github.com/sst/opencode)               | OpenCode CLI         | `npm install -g opencode`                                                                                              |
| [`pi`](https://github.com/badlogic/pi-mono)                 | Pi CLI agent         | See [repo](https://github.com/badlogic/pi-mono)                                                                        |
| [`qwen`](https://github.com/QwenLM/qwen-code)               | Alibaba Qwen Code    | See [repo](https://github.com/QwenLM/qwen-code)                                                                        |

> [!TIP]
> After installing tools, restart Neovim or run `:Ajans cli select` to see them available.

## 🚀 Commands

Ajans provides a `:Ajans` command for CLI workflows from the command line. The command is a thin wrapper around the `require("ajans.cli")` API.

### Command Structure

The command structure is simple:

```
:Ajans <module> <command> [args]
```

- `<module>`: The name of the module you want to use (currently `cli`).
- `<command>`: The name of the command you want to execute.
- `[args]`: Optional arguments for the command. The arguments are parsed as a Lua
  table.

For example, to show the CLI window for the `claude` tool, you can use the
following command:

```
:Ajans cli show name=claude
```

This is equivalent to the following Lua code:

```lua
require("ajans.cli").show({ name = "claude" })
```

<details><summary>
<strong>Available Commands</strong></summary>

Here's a list of the available commands:

**CLI (`cli`)**

- `show`: Show the CLI window.
- `toggle`: Toggle the CLI window.
- `hide`: Hide the CLI window.
- `close`: Close the CLI window.
- `focus`: Focus the CLI window.
- `select`: Select a CLI tool to open.
- `send`: Send a message to the current CLI tool.
- `prompt`: Select a prompt to send to the current CLI tool.

</details>

<details><summary>
<strong>Examples</strong></summary>

Here are some examples of how to use the `:Ajans` command:

- Toggle the CLI window:

  ```
  :Ajans cli toggle
  ```

  Lua equivalent:

  ```lua
  require("ajans.cli").toggle()
  ```

- Send the visual selection to the current CLI tool:

  ```
  :'<,'>Ajans cli send msg="{selection}"
  ```

  Lua equivalent:

  ```lua
  require("ajans.cli").send({ msg = "{selection}" })
  ```

- Show the CLI window for the `grok` tool and focus it:

  ```
  :Ajans cli show name=grok focus=true
  ```

  Lua equivalent:

  ```lua
  require("ajans.cli").show({ name = "grok", focus = true })
  ```

  </details>

## 📟 Statusline Integration

Using the `require("ajans.status")` API, you can integrate active **CLI sessions**
in your statusline.

<details>
<summary>Example for <a href="https://github.com/nvim-lualine/lualine.nvim">lualine.nvim</a></summary>

<!-- setup_lualine:start -->

```lua
{
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}

    -- CLI session status
    table.insert(opts.sections.lualine_x, 2, {
      function()
        local status = require("ajans.status").cli()
        return " " .. (#status > 1 and #status or "")
      end,
      cond = function()
        return #require("ajans.status").cli() > 0
      end,
      color = function()
        return "Special"
      end,
    })
  end,
}
```

<!-- setup_lualine:end -->

</details>

## ❓ FAQ

### CLI tools not starting?

1. Verify the tool is installed: `which claude` (or your tool name)
2. Check `:checkhealth ajans` for tool installation status
3. Try running the tool directly in your terminal first
4. Check for errors with `:messages` after attempting to start

### Terminal sessions not persisting?

Make sure you have tmux installed. Ajans always runs CLI sessions through tmux.

### Do I need a GitHub Copilot subscription?

No. Ajans works with any supported AI CLI tool. You only need a Copilot
subscription if you choose to use Copilot CLI itself.

### Will this work with Neovim 0.10?

No, Neovim **>= 0.11.2** is required for the APIs used by ajans.nvim.

### How do I add my own AI tool?

Add it to the `cli.tools` configuration:

```lua
opts = {
  cli = {
    tools = {
      my_tool = {
        cmd = { "my-ai-cli", "--flag" },
        -- Optional: custom keymaps for this tool
        keys = {
          submit = { "<c-s>", function(t) t:send("\n") end },
        },
      },
    },
  },
}
```

### How do I create custom prompts?

Add them to your config:

```lua
opts = {
  cli = {
    prompts = {
      refactor = "Please refactor {this} to be more maintainable",
      security = "Review {file} for security vulnerabilities",
      custom = function(ctx)
        return "Current file: " .. ctx.buf .. " at line " .. ctx.row
      end,
    },
  },
}
```

Then use with `<leader>ap` or `:Ajans cli prompt`.
