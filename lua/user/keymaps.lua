local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", {desc = "leader 修改为 space"})
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
-- keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-h>", "<C-w>h", { desc = "切换窗口h"})
keymap("n", "<C-j>", "<C-w>j", { desc = "切换窗口j"})
keymap("n", "<C-k>", "<C-w>k", { desc = "切换窗口k"})
keymap("n", "<C-l>", "<C-w>l", { desc = "切换窗口l"})

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", {desc = "调整窗口大小"})
keymap("n", "<C-Down>", ":resize +2<CR>", {desc = "调整窗口大小"})
keymap("n", "<C-Left>", ":vertical resize -2<CR>", {desc = "调整窗口大小"})
keymap("n", "<C-Right>", ":vertical resize +2<CR>", {desc = "调整窗口大小"})

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", {desc = "切换buffer"})
keymap("n", "<S-h>", ":bprevious<CR>", {desc = "切换buffer"})
-- Move text up and down
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", {desc = "文本下移"})
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", {desc = "文本上移"})

-- Insert --
-- Press jk fast to enter
-- keymap("i", "jk", "<ESC>", opts)
-- keymap("i", "kj", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", {desc = "文本下移"})
keymap("v", "<A-k>", ":m .-2<CR>==", {desc = "文本上移"})
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- quickfix
keymap("n", "cc", ":ccl<CR>", {desc = "关闭quickfix"})

-- Terminal --
-- commandline 提示切换
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

keymap("n", "<F3>", ":SymbolsOutline<CR>", {desc = "打开/关闭符号表"})

vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', {
    desc = "打开/关闭搜索页"
})
vim.keymap.set('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
    desc = "搜索当前单词"
})
vim.keymap.set('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', {
    desc = "搜索当前内容"
})
vim.keymap.set('n', '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
    desc = "搜索当前文件"
})

