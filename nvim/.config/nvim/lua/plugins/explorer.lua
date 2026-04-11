return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        width = 30,
        -- Strip out all write/mutate operations — tree is view-only
        mappings = {
          ["a"]     = "none",
          ["d"]     = "none",
          ["r"]     = "none",
          ["y"]     = "none",
          ["x"]     = "none",
          ["p"]     = "none",
          ["m"]     = "none",
          ["c"]     = "none",
          ["q"]     = "none",
          -- Disable opening files from neo-tree entirely; use Telescope instead
          ["<cr>"]  = "none",
          ["o"]     = "none",
          ["<2-LeftMouse>"] = "none",
        },
      },
    })

    -- Prevent neo-tree from ever auto-focusing when it opens
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      callback = function()
        -- Immediately return focus to the previous window whenever
        -- the cursor lands in neo-tree (covers edge-cases like startup)
        vim.schedule(function()
          local wins = vim.api.nvim_list_wins()
          for _, w in ipairs(wins) do
            local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
            if ft ~= "neo-tree" then
              vim.api.nvim_set_current_win(w)
              return
            end
          end
        end)
      end,
    })
  end,
}
