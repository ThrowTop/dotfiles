return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "onedark",
                globalstatus = true,
                component_separators = "",
                section_separators = "",
                disabled_filetypes = { statusline = { "alpha" } },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "diagnostics", "filetype" },
                lualine_y = {},
                lualine_z = {},
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { { "filename", path = 1 } },
                lualine_x = {},
                lualine_y = {},
                lualine_z = {},
            },
            tabline = {
                lualine_a = {
                    {
                        "buffers",
                        mode = 2,
                        show_filename_only = true,
                        use_mod_mark = true,
                        symbols = { modified = " ●", alternate_file = "", directory = "" },
                        max_length = vim.o.columns,
                    },
                },
                lualine_z = { { "tabs", mode = 1 } },
            },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            current_line_blame = false,
            signcolumn = true,
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
            delay = 0,
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = { char = "│", tab_char = "│" },
            scope = { enabled = false },
            exclude = {
                filetypes = {
                    "help", "alpha", "dashboard", "lazy", "mason",
                    "notify", "toggleterm",
                    "TelescopePrompt", "TelescopeResults", "TelescopePreview",
                },
                buftypes = { "terminal", "nofile", "quickfix", "prompt" },
            },
        },
    },
}
