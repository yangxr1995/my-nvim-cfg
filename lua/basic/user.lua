-- 定义一个函数来打开调试
function open_debug()
    vim.cmd [[ set nonu ]]
    vim.cmd [[ packadd termdebug ]]
    vim.cmd [[ Termdebug ./test ]]
end

-- 绑定 F5 键到 open_debug 函数
-- vim.api.nvim_set_keymap('n', '<F11>', ':lua open_debug()<CR>', { noremap = true, silent = true })
