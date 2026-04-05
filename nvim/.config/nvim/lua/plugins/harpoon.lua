return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    -- Telescope picker for harpoon list
    local function harpoon_telescope()
      local file_paths = {}
      for _, item in ipairs(harpoon:list().items) do
        table.insert(file_paths, item.value)
      end

      local conf = require("telescope.config").values
      require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({ results = file_paths }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
      }):find()
    end

    -- Space+a: add current file to harpoon
    vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { noremap = true, silent = true })

    -- Space+h: open harpoon list in telescope
    vim.keymap.set("n", "<leader>h", harpoon_telescope, { noremap = true, silent = true })
  end,
}
