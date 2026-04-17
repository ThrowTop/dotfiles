return {
    {
        "saghen/blink.cmp",
        version = "*",
        event = "InsertEnter",
        opts = {
            keymap = {
                preset = "none",
                ["<Tab>"]     = { "snippet_forward", "select_and_accept", "fallback" },
                ["<S-Tab>"]   = { "snippet_backward", "fallback" },
                ["<Up>"]      = { "select_prev", "fallback" },
                ["<Down>"]    = { "select_next", "fallback" },
                ["<CR>"]      = { "fallback" },
                ["<C-Space>"] = { "show" },
                ["<C-k>"]     = { "show_documentation", "hide_documentation" },
                ["<C-e>"]     = { "hide" },
            },
            completion = {
                list = {
                    selection = { preselect = false, auto_insert = false },
                },
                menu = {
                    auto_show = true,
                    border = "rounded",
                    draw = { treesitter = { "lsp" } },
                },
                ghost_text = { enabled = false },
                documentation = { auto_show = false, window = { border = "rounded" } },
            },
            fuzzy = {
                implementation = "prefer_rust_with_warning",
                sorts = { "score", "sort_text" },
            },
            signature = { enabled = true, window = { border = "rounded" } },
            sources = {
                default = { "lsp", "path", "buffer" },
            },
            appearance = {
                use_nvim_cmp_as_default = false,
                nerd_font_variant = "mono",
            },
        },
    },
}
