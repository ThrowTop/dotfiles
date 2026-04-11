return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua        = { "stylua" },
        python     = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json       = { "prettier" },
        css        = { "prettier" },
        html       = { "prettier" },
        markdown   = { "prettier" },
        sh         = { "shfmt" },
      },
      -- Format on save; fall back to LSP if no formatter is installed
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })
  end,
}
