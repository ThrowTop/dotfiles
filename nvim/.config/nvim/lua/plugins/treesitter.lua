return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        dependencies = {
            { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
            "RRethy/nvim-treesitter-endwise",
        },
        config = function()
            require("nvim-treesitter").install({
                "lua", "vim", "vimdoc", "bash", "cpp", "fish",
                "hyprlang", "ini", "markdown", "markdown_inline",
            })

            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
                    if lang and pcall(vim.treesitter.language.add, lang) then
                        pcall(vim.treesitter.start, args.buf, lang)
                        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
