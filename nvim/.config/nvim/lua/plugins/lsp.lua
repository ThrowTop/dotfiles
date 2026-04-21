-- Add LSP servers to this list to enable them. Mason installs them automatically,
-- and mason-lspconfig v2 calls vim.lsp.enable() on each. Per-server options go here.
local servers = {
    lua_ls = {
        settings = {
            Lua = {
                workspace = {
                    checkThirdParty = false,
                    -- Hyprland stubs: teaches LSP about hl.* and all HL.* types
                    library = { "/home/throw/custom/repos/Hyprland/meta" },
                },
                telemetry = { enable = false },
                diagnostics = { globals = { "vim", "hl" } },
            },
        },
    },
    clangd = {},
}

return {
    { "williamboman/mason.nvim", cmd = "Mason", build = ":MasonUpdate", opts = {} },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local caps = vim.lsp.protocol.make_client_capabilities()
            local ok, blink = pcall(require, "blink.cmp")
            if ok then
                caps = blink.get_lsp_capabilities(caps)
            end

            vim.lsp.config("*", { capabilities = caps })
            for name, cfg in pairs(servers) do
                vim.lsp.config(name, cfg)
            end

            -- Only ask Mason to install servers NOT available on PATH.
            -- clangd typically ships via `pacman -S clang` — let mason-lspconfig
            -- auto-enable it from the system install without trying to re-download.
            local mason_install = {}
            for name, _ in pairs(servers) do
                local bin = name == "lua_ls" and "lua-language-server" or name
                if vim.fn.executable(bin) ~= 1 then
                    table.insert(mason_install, name)
                end
            end

            require("mason-lspconfig").setup({
                ensure_installed = mason_install,
                automatic_enable = true,
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                end,
            })

            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                severity_sort = true,
                update_in_insert = false,
            })
        end,
    },
}
