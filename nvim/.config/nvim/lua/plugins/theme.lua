return {
  "olimorris/onedarkpro.nvim",
  priority = 1000, -- load before everything else
  config = function()
    require("onedarkpro").setup({
      styles = {
        comments = "italic",
        keywords = "bold",
      },
      options = {
        cursorline = true,
      },
    })
    vim.cmd("colorscheme onedark")
  end,
}
