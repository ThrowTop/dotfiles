return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master", -- main branch requires nvim 0.12 nightly; master is stable for 0.11
  build = ":TSUpdate",
  dependencies = {
    "RRethy/nvim-treesitter-endwise",
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "vim", "vimdoc" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      endwise = { enable = true },
    })
  end,
}
