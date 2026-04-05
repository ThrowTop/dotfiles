return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({
      options = {
        -- Hide directory buffers (the empty tab from nvim .)
        custom_filter = function(buf_number)
          if vim.fn.isdirectory(vim.fn.bufname(buf_number)) == 1 then
            return false
          end
          return true
        end,
        -- Don't show neo-tree buffer as a tab
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            separator = true,
          },
        },
        -- Close button on each tab
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        -- Show buffer index for jumping (leader + number)
        numbers = "ordinal",
        -- Don't show bufferline if only one file open
        always_show_bufferline = false,
      },
    })
  end,
}
