return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
            },
        },
        config = function(_, opts)
            require("conform").setup(opts)
            vim.api.nvim_create_autocmd("BufWritePre", {
                callback = function(args)
                    require("conform").format({
                        bufnr = args.buf,
                        timeout_ms = 500,
                        lsp_format = "fallback",
                    })
                    local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
                    while #lines > 0 and lines[#lines] == "" do
                        table.remove(lines)
                    end
                    table.insert(lines, "")
                    table.insert(lines, "")
                    vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
                end,
            })
        end,
    },
}
