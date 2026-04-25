return {
    -- {
    --     "folke/flash.nvim",
    --     event = "VeryLazy",
    --     opts = {
    --         modes = {
    --             search = { enabled = false },
    --             char = { enabled = false },
    --         },
    --     },
    --     keys = {
    --         { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
    --     },
    -- },

    {
        "echasnovski/mini.ai",
        version = "*",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local ai = require("mini.ai")

            -- Zed-style indent text objects:
            --   ii  = inside indent block only
            --   ai  = indent block + one line before        (key "i", ai_type "a")
            --   aI  = indent block + one line before+after  (key "I", ai_type "a")
            local function make_indent_textobj(add_before, add_after)
                return function(ai_type)
                    local buf = vim.api.nvim_get_current_buf()
                    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
                    local total = vim.api.nvim_buf_line_count(buf)

                    local function get_indent(row)
                        local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
                        if line:match("^%s*$") then return nil end
                        return #(line:match("^(%s*)"))
                    end

                    local cur_ind = get_indent(cursor_row)
                    if cur_ind == nil then return nil end

                    local top = cursor_row
                    while top > 1 do
                        local ind = get_indent(top - 1)
                        if ind == nil or ind < cur_ind then break end
                        top = top - 1
                    end

                    local bot = cursor_row
                    while bot < total do
                        local ind = get_indent(bot + 1)
                        if ind == nil or ind < cur_ind then break end
                        bot = bot + 1
                    end

                    if ai_type == "a" then
                        if add_before and top > 1 then top = top - 1 end
                        if add_after and bot < total then bot = bot + 1 end
                    end

                    local lines = vim.api.nvim_buf_get_lines(buf, top - 1, bot, false)
                    return {
                        from = { line = top, col = 1 },
                        to = { line = bot, col = #lines[#lines] },
                    }
                end
            end

            ai.setup({
                n_lines = 500,
                custom_textobjects = {
                    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
                    a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
                    i = make_indent_textobj(true, false),
                    I = make_indent_textobj(true, true),
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
                { '"', '"' },
                { "'", "'" },
                { "`", "`" },
                { "(", ")" },
                { ")", ")" },
                { "[", "]" },
                { "]", "]" },
                { "{", "}" },
                { "}", "}" },
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


