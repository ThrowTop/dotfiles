return {
  "numToStr/Comment.nvim",
  lazy = false,
  config = function()
    require("Comment").setup()

    -- Ctrl+/ to toggle line comment in normal mode
    vim.keymap.set("n", "<C-/>", function()
      require("Comment.api").toggle.linewise.current()
    end, { noremap = true, silent = true })

    -- Ctrl+/ to toggle line comment over visual selection
    vim.keymap.set("v", "<C-/>", function()
      local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
      vim.api.nvim_feedkeys(esc, "nx", false)
      require("Comment.api").toggle.linewise(vim.fn.visualmode())
    end, { noremap = true, silent = true })
  end,
}
