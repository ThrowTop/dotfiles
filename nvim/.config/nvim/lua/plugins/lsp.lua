return {
  -- Completion engine
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
        preset = "none",
        ["<Tab>"]   = { "accept", "select_next", "fallback" },
        ["<Right>"] = { "accept", "fallback" },
        ["<Down>"]  = { "select_next", "fallback" },
        ["<Up>"]    = { "select_prev", "fallback" },
        ["j"]       = { "select_next", "fallback" },
        ["k"]       = { "select_prev", "fallback" },
        ["<CR>"]    = { "cancel", "fallback" },
        ["<Esc>"]   = { "cancel", "fallback" },
        ["<C-Space>"] = { "show", "fallback" },
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        menu = { border = "rounded" },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  -- mason-lspconfig v2 (repos moved to mason-org)
  -- setup_handlers is gone; mason now uses vim.lsp.enable() natively
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },
    config = function()
      -- Pass blink.cmp capabilities to every LSP server via wildcard
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- mason-lspconfig v2: automatic_enable calls vim.lsp.enable() for each installed server
      -- lua_ls: tell it we're in a Neovim context so `vim` global is known
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            diagnostics = { globals = { "vim", "hl" } },
            telemetry = { enable = false },
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          -- Add more language servers to auto-install, e.g.:
          -- "pyright",
          -- "ts_ls",
          -- "rust_analyzer",
          -- "gopls",
        },
        automatic_enable = true,
      })

      -- LSP keymaps, only active when LSP attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf, noremap = true, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)          -- go to definition
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)          -- show references
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)                -- hover docs
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)      -- rename symbol
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- code actions
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)        -- prev diagnostic
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)        -- next diagnostic
        end,
      })

      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        float = { border = "rounded" },
      })
    end,
  },
}
