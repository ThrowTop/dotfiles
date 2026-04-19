local map = vim.keymap.set

map({ "i", "v", "c" }, "<F19>", "<Esc>", { silent = true })

map("i", "<C-BS>", "<C-w>", { silent = true })

map("n", "<C-s>", "<cmd>w<CR>", { silent = true })
map("i", "<C-s>", "<Esc><cmd>w<CR>", { silent = true })

map({ "n", "v" }, "d", '"_d', { silent = true })
map("n", "dd", '"_dd', { silent = true })

map("v", "<C-c>", '"+y', { silent = true })

map("n", "<C-Tab>", "<cmd>bnext<CR>", { silent = true })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { silent = true })

local function close_buffer()
    local listed = vim.fn.getbufinfo({ buflisted = 1 })
    if #listed > 1 then
        vim.cmd("bpreviouu")
        vim.cmd("bdelete! #")
    else
        vim.cmd("quit!")
    end
end
map("n", "<C-w>", close_buffer, { silent = true })

for i = 1, 9 do
    map("n", "<leader>" .. i, function()
        local listed = vim.fn.getbufinfo({ buflisted = 1 })
        if listed[i] then
            vim.cmd("buffer " .. listed[i].bufnr)
        end
    end, { silent = true })
end

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })

map("n", ";", ":", { silent = false })

map("n", "<C-d>", "<C-d>zz", { silent = true })
map("n", "<C-u>", "<C-u>zz", { silent = true })
map("n", "n", "nzzzv", { silent = true })
map("n", "N", "Nzzzv", { silent = true })

map("n", "J", "mzJ`z", { silent = true })

map("n", "<A-j>", "<cmd>m .+1<CR>==", { silent = true })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { silent = true })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { silent = true })

map("v", "<", "<gv", { silent = true })
map("v", ">", ">gv", { silent = true })

map("v", "p", '"_dP', { silent = true })

map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })

map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

for _, click in ipairs({
    "<LeftMouse>",
    "<LeftDrag>",
    "<LeftRelease>",
    "<2-LeftMouse>",
    "<3-LeftMouse>",
    "<4-LeftMouse>",
    "<RightMouse>",
    "<MiddleMouse>",
}) do
    map({ "n", "i", "v" }, click, "<Nop>", { silent = true })
end

local toggle_pairs = {
    { "true", "false" },
    { "and", "or" },
    { "yes", "no" },
    { "on", "off" },
}
local toggle_lut = {}
for _, p in ipairs(toggle_pairs) do
    toggle_lut[p[1]], toggle_lut[p[2]] = p[2], p[1]
end

map("n", "<leader>t", function()
    local word = vim.fn.expand("<cword>")
    local new = toggle_lut[word:lower()]
    if not new then
        vim.notify("no toggle for '" .. word .. "'")
        return
    end
    if word == word:upper() then
        new = new:upper()
    elseif word:sub(1, 1) == word:sub(1, 1):upper() then
        new = new:sub(1, 1):upper() .. new:sub(2)
    end
    local keys = vim.api.nvim_replace_termcodes('"_ciw' .. new .. "<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Toggle boolean/keyword under cursor" })

map("n", "<leader>w", function()
    vim.opt.wrap = not vim.opt.wrap:get()
    vim.opt.linebreak = vim.opt.wrap:get()
    vim.notify("wrap: " .. tostring(vim.opt.wrap:get()))
end, { desc = "Toggle line wrap" })


