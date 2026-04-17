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
            { "s", function() require("flash").jump() end,       mode = { "n", "x", "o" }, desc = "Flash jump" },
            { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
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
                    c = ai.gen_spec.treesitter({ a = "@class.outer",     i = "@class.inner" }),
                    a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
                    l = ai.gen_spec.treesitter({ a = "@loop.outer",      i = "@loop.inner" }),
                    i = ai.gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
                },
            })
        end,
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
