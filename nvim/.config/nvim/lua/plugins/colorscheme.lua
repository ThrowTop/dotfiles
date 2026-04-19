return {
    {
        "navarasu/onedark.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("onedark").setup({
                style = "dark",
                transparent = false,
                term_colors = true,
                code_style = {
                    comments = "italic",
                    keywords = "none",
                    functions = "none",
                    strings = "none",
                    variables = "none",
                },
                diagnostics = {
                    darker = true,
                    undercurl = true,
                    background = true,
                },
            })
            require("onedark").load()

            vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
                undercurl = true,
                sp = "#c678dd",
            })
        end,
    },
}
