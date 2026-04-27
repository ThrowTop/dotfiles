return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            -- Powerline glyphs via explicit UTF-8 bytes — avoids editor stripping
            local arrow_r      = string.char(0xEE, 0x82, 0xB0) -- U+E0B0
            local arrow_l      = string.char(0xEE, 0x82, 0xB2) -- U+E0B2
            local arrow_r_thin = string.char(0xEE, 0x82, 0xB1) -- U+E0B1
            local arrow_l_thin = string.char(0xEE, 0x82, 0xB3) -- U+E0B3

            -- Match onedarkpro_vivid gray bg overrides
            local base      = "#1e1e1e"
            local mantle    = "#181818"
            local surface0  = "#252525"
            local surface1  = "#383838"
            local subtext0  = "#abb2bf"  -- onedark fg_dark
            local subtext1  = "#c8ccd4"  -- onedark fg

            local purple_dark = "#3b1f6e"  -- deep dark purple for NORMAL + active tab
            local purple_fg   = "#ddd0ff"  -- soft lavender text on purple bg

            local theme = {
                normal = {
                    a = { fg = purple_fg, bg = purple_dark, gui = "bold" },
                    b = { fg = subtext1,  bg = surface0 },
                    c = { fg = subtext0,  bg = mantle },
                },
                insert = {
                    a = { fg = base,     bg = "#1f5c3a", gui = "bold" },
                    b = { fg = subtext1, bg = surface0 },
                    c = { fg = subtext0, bg = mantle },
                },
                visual = {
                    a = { fg = purple_fg, bg = "#5a2d8a", gui = "bold" },
                    b = { fg = subtext1,  bg = surface0 },
                    c = { fg = subtext0,  bg = mantle },
                },
                replace = {
                    a = { fg = base,     bg = "#7a2020", gui = "bold" },
                    b = { fg = subtext1, bg = surface0 },
                    c = { fg = subtext0, bg = mantle },
                },
                command = {
                    a = { fg = base,     bg = "#7a5a1a", gui = "bold" },
                    b = { fg = subtext1, bg = surface0 },
                    c = { fg = subtext0, bg = mantle },
                },
                inactive = {
                    a = { fg = surface1, bg = mantle },
                    b = { fg = surface1, bg = mantle },
                    c = { fg = surface1, bg = mantle },
                },
            }

            require("lualine").setup({
                options = {
                    theme = theme,
                    globalstatus = true,
                    component_separators = { left = arrow_r_thin, right = arrow_l_thin },
                    section_separators   = { left = arrow_r,      right = arrow_l },
                    disabled_filetypes   = { statusline = { "alpha" } },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = {
                        { "branch", icon = "" },
                        {
                            "diff",
                            symbols = { added = " ", modified = " ", removed = " " },
                            source = function()
                                local gs = vim.b.gitsigns_status_dict
                                return gs and { added = gs.added, modified = gs.changed, removed = gs.removed }
                            end,
                        },
                    },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = {
                        {
                            "diagnostics",
                            symbols = { error = " ", warn = " ", info = " ", hint = " " },
                        },
                        "filetype",
                    },
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
                    lualine_z = {},
                },
            })
        end,
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
