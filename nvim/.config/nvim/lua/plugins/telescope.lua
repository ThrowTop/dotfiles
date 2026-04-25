return {
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        keys = {
            { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
            {
                "<leader>e",
                function()
                    require("telescope").extensions.file_browser.file_browser({
                        path = "%:p:h",
                        select_buffer = true,
                    })
                end,
                desc = "File browser",
            },
            {
                "<leader>p",
                function() require("projects").pick() end,
                desc = "Switch project",
            },
            { "<C-f>", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },
            { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },
            { "<leader>g", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
            { "<leader>b", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
            { "<leader>sh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
            { "<leader>sk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
            { "<leader>sc", "<cmd>Telescope commands<CR>", desc = "Commands" },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "nvim-telescope/telescope-file-browser.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            telescope.setup({
                defaults = {
                    prompt_prefix = " ❯ ",
                    selection_caret = " ❯ ",
                    entry_prefix = "   ",
                    multi_icon = "│",
                    sorting_strategy = "ascending",
                    layout_config = {
                        horizontal = { prompt_position = "top", preview_width = 0.55 },
                        width = 0.9,
                        height = 0.85,
                    },
                    mappings = {
                        i = {
                            ["<Esc>"] = actions.close,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        },
                    },
                },
                extensions = {
                    file_browser = {
                        hijack_netrw = true,
                        grouped = true,
                        hidden = true,
                        respect_gitignore = false,
                        display_stat = { date = true, size = true },
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })
            telescope.load_extension("file_browser")
            telescope.load_extension("ui-select")
        end,
    },
}
