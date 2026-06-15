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

-- Window/Pane navigation handled by smart-splits.nvim (see plugins/tmux.lua)

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
keymap("n", "<leader>cq", ":ccl<CR>", { noremap = true, silent = true, desc = "关闭quickfix" })

-- Terminal mode navigation handled by smart-splits.nvim (see plugins/tmux.lua)


-- high light
local function cursor_line_highlight()
    -- 获取光标位置
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1]

    vim.cmd("match Search /\\%" .. line_num .. "l/")
end

vim.keymap.set("n", "<leader>cl", cursor_line_highlight, { desc = "获取当前行" })
vim.keymap.set("n", "<leader>cc", ":match None<CR>", { desc = "取消高亮" })

