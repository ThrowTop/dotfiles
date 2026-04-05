-- Neovim config
-- Basic editor settings with lazy.nvim plugins

-- Indentation: 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Display
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.wrap = true

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- Behavior
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.splitbelow = true
vim.opt.splitright = true

-- NO swap, backup, or undo files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false

-- Colors
vim.opt.termguicolors = true

-- Performance
vim.opt.lazyredraw = true
vim.opt.updatetime = 300

-- Leader key
vim.g.mapleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup("plugins", {
  install = { colorscheme = { "onedark" } },
})

-- Suppress unsaved changes nag. q/wq behave normally otherwise.
vim.cmd("cnoreabbrev q q!")
vim.cmd("cnoreabbrev wq wq!")

-- Close just the current split/window (help, preview, etc) without quitting neovim
vim.keymap.set("n", "<leader>q", "<C-w>q", { noremap = true, silent = true })

-- Keybindings
-- Ctrl+S to save
vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-s>", "<ESC>:w<CR>", { noremap = true, silent = true })

-- Ctrl+C to copy (visual mode)
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true })

-- Ctrl+V to paste
vim.keymap.set("i", "<C-v>", '<ESC>"+pa', { noremap = true, silent = true })
vim.keymap.set("n", "<C-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("v", "<C-v>", '"+p', { noremap = true, silent = true })

-- <leader>e to toggle file explorer (Space + e)
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { noremap = true, silent = true })

-- <leader>p to fuzzy find files (Space + p)
-- searches from cwd, so works both in nvim . and nvim <file>
vim.keymap.set("n", "<leader>p", ":Telescope find_files<CR>", { noremap = true, silent = true })

-- <leader>/ to fuzzy search inside the current buffer
vim.keymap.set("n", "<leader>/", ":Telescope current_buffer_fuzzy_find<CR>", { noremap = true, silent = true })

-- Buffer/tab navigation
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })

-- Ctrl+W closes current buffer without closing neovim
-- If it's the last buffer, just quit neovim
local function close_buffer()
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  if #listed > 1 then
    vim.cmd("bprevious")
    vim.cmd("bdelete! #")
  else
    vim.cmd("quit!")
  end
end
vim.keymap.set("n", "<C-w>", close_buffer, { noremap = true, silent = true })

-- Jump to buffer by number: Space + 1-9
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    require("bufferline").go_to(i, true)
  end, { noremap = true, silent = true })
end
