return {
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {},
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
            { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics (Trouble)" },
            { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols (Trouble)" },
            { "<leader>xr", "<cmd>Trouble lsp toggle focus=false<CR>", desc = "LSP refs/defs (Trouble)" },
            { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix (Trouble)" },
        },
    },

    {
        "echasnovski/mini.files",
        version = "*",
        keys = {
            {
                "<leader>E",
                function()
                    local mf = require("mini.files")
                    if not mf.close() then
                        mf.open(vim.api.nvim_buf_get_name(0))
                    end
                end,
                desc = "File tree (mini.files)",
            },
        },
        opts = {
            windows = { preview = true, width_preview = 50 },
        },
    },
}


