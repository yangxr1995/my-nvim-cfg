vim.g.mapleader = " "
vim.g.maplocalleader = " "


-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true, desc = "切换窗口h" })
keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true, desc = "切换窗口j" })
keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true, desc = "切换窗口k" })
keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "切换窗口l" })

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", { noremap = true, silent = true, desc = "调整窗口大小" })
keymap("n", "<C-Down>", ":resize +2<CR>", { noremap = true, silent = true, desc = "调整窗口大小" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { noremap = true, silent = true, desc = "调整窗口大小" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { noremap = true, silent = true, desc = "调整窗口大小" })

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", { noremap = true, silent = true, desc = "切换buffer" })
keymap("n", "<S-h>", ":bprevious<CR>", { noremap = true, silent = true, desc = "切换buffer" })
-- Move text up and down
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", { noremap = true, silent = true, desc = "文本下移" })
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", { noremap = true, silent = true, desc = "文本上移" })

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", { noremap = true, silent = true, desc = "文本移动" })
keymap("x", "K", ":move '<-2<CR>gv-gv", { noremap = true, silent = true, desc = "文本移动" })
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", { noremap = true, silent = true, desc = "文本块移动" })
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", { noremap = true, silent = true, desc = "文本块移动" })

-- quickfix
keymap("n", "cc", ":ccl<CR>", { noremap = true, silent = true, desc = "关闭quickfix" })

-- Terminal --
-- commandline 提示切换
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)
