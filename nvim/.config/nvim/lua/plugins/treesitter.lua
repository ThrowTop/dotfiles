return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            -- Query files only (queries/<lang>/textobjects.scm). We don't call its
            -- setup — mini.ai reads the queries from the runtimepath.
            { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
            -- Auto-insert `end` after `function`/`if`/`for`/`while`/`do` (Lua, Ruby, etc.)
            "RRethy/nvim-treesitter-endwise",
        },
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "lua", "vim", "vimdoc" },
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
                endwise = { enable = true },
            })
        end,
    },
}
