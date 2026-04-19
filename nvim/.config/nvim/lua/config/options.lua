local o = vim.opt

o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true
o.autoindent = true
o.smartindent = true

o.number = true
o.relativenumber = true
o.cursorline = true
o.cursorlineopt = "number"
o.wrap = false
o.signcolumn = "yes"
o.scrolloff = 4
o.termguicolors = true

o.ignorecase = true
o.smartcase = true
o.hlsearch = true

o.mouse = "a"
o.clipboard = "unnamedplus"
o.splitbelow = true
o.splitright = true

o.swapfile = false
o.backup = false
o.writebackup = false
o.undofile = false

o.updatetime = 250
o.timeoutlen = 400

o.shortmess:append("IWcC")

o.completeopt = { "menu", "menuone", "noselect", "noinsert" }

vim.diagnostic.config({
    virtual_text = { prefix = "●", spacing = 2 },
    severity_sort = true,
    float = { border = "rounded", source = true },
})

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})

vim.cmd("cnoreabbrev q q!")
vim.cmd("cnoreabbrev wq wq!")
vim.cmd("cnoreabbrev W w")
vim.cmd("cnoreabbrev Q q!")
vim.cmd("cnoreabbrev Wq wq!")
vim.cmd("cnoreabbrev WQ wq!")


