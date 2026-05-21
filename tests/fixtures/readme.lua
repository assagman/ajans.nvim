local base = {
  "assagman/ajans.nvim",
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "zellij",
        enabled = true,
      },
    },
  },
  -- stylua: ignore
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("ajans").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
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

local custom = {
  "assagman/ajans.nvim",
  opts = {
    -- add any options here
  },
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if require("ajans").nes_jump_or_apply() then
          return -- jumped or applied
        end

        -- if you are using Neovim's native inline completions
        if vim.lsp.inline_completion.get() then
          return
        end

        -- any other things (like snippets) you want to do on <tab> go here.

        -- fall back to normal tab
        return "<tab>"
      end,
      mode = { "i", "n" },
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
  },
}

local blink = {
  "saghen/blink.cmp",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {

    keymap = {
      ["<Tab>"] = {
        "snippet_forward",
        function() -- ajans next edit suggestion
          return require("ajans").nes_jump_or_apply()
        end,
        function() -- if you are using Neovim's native inline completions
          return vim.lsp.inline_completion.get()
        end,
        "fallback",
      },
    },
  },
}

local lualine = {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_c = opts.sections.lualine_c or {}

    -- Copilot status
    table.insert(opts.sections.lualine_c, {
      function()
        return " "
      end,
      color = function()
        local status = require("ajans.status").get()
        if status then
          return status.kind == "Error" and "DiagnosticError" or status.busy and "DiagnosticWarn" or "Special"
        end
      end,
      cond = function()
        local status = require("ajans.status")
        return status.get() ~= nil
      end,
    })

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

local snacks_picker = {
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
