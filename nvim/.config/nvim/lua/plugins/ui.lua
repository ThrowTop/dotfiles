return {
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "onedark",
          globalstatus = true, -- single statusline across all splits
        },
      })
    end,
  },

  -- Git decorations in the gutter (added/removed/changed lines)
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame = false, -- toggle with :Gitsigns toggle_current_line_blame
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = true },
      })
    end,
  },

  -- Shows available keybinds after pressing leader (or any key)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },

  -- Auto-close brackets, parens, quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Animated cursor
  {
    "sphamba/smear-cursor.nvim",
    opts = {},
  },
}
