return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            modes = {
                search = { enabled = false },
                char = { enabled = false },
            },
        },
        keys = {
            { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
        },
    },

    {
        "echasnovski/mini.ai",
        version = "*",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local ai = require("mini.ai")
            ai.setup({
                n_lines = 500,
                custom_textobjects = {
                    f = ai.gen_spec.treesitter({ a = "@function.outer",  i = "@function.inner" }),
                    a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
                },
            })
        end,
    },

    {
        "echasnovski/mini.indentscope",
        version = "*",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            symbol = "│",
            options = { try_as_border = true },
            draw = { animation = function() return 0 end },
        },
    },

    {
        "echasnovski/mini.bracketed",
        version = "*",
        event = { "BufReadPost", "BufNewFile" },
        opts = {},
    },

    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        opts = {},
        init = function()
            local map = vim.keymap.set
            local pairs_to_bind = {
                { '"', '"' }, { "'", "'" }, { "`", "`" },
                { "(", ")" }, { ")", ")" },
                { "[", "]" }, { "]", "]" },
                { "{", "}" }, { "}", "}" },
            }
            for _, p in ipairs(pairs_to_bind) do
                map("x", p[1], "S" .. p[2], { remap = true, desc = "Surround with " .. p[2] })
            end
        end,
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {
            check_ts = true,
            fast_wrap = {},
        },
    },
}
