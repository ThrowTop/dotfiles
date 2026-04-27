return {
    {
        "olimorris/onedarkpro.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("onedarkpro").setup({
                colors = {
                    onedark_vivid = {
                        -- swap the blue-gray bg for neutral industrial gray
                        bg              = "#1e1e1e",
                        bg_highlight    = "#252525",
                        color_column    = "#252525",
                        float_bg        = "#181818",
                    },
                },
                highlights = {
                    -- purple accents on UI chrome only, syntax untouched
                    LineNr          = { fg = "#6b5590" },
                    LineNrAbove     = { fg = "#4e3d6e" },
                    LineNrBelow     = { fg = "#4e3d6e" },
                    CursorLineNr    = { fg = "#b87fff", bold = true },
                    CursorLine      = { bg = "#231e2e" },
                    Visual          = { bg = "#2d2045" },
                    WinSeparator    = { fg = "#3d2d55" },
                    IblIndent       = { fg = "#28203a" },
                    TelescopeSelection = { fg = "#e0d8f0", bg = "#2d2045" },
                },
                styles = {
                    comments = "italic",
                },
                options = {
                    bold             = true,
                    italic           = true,
                    undercurl        = true,
                    cursorline       = true,
                    transparency     = false,
                    terminal_colors  = true,
                },
            })
            vim.cmd("colorscheme onedark_vivid")
        end,
    },
}
