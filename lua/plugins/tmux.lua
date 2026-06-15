return {
    {
        'mrjones2014/smart-splits.nvim',
        lazy = false,
        config = function()
            require('smart-splits').setup({
                multiplexer_integration = 'zellij',
                zellij_move_focus_or_tab = true,
            })

            local ss = require('smart-splits')
            vim.keymap.set('n', '<C-h>', ss.move_cursor_left, { desc = '窗口/Pane 左移' })
            vim.keymap.set('n', '<C-j>', ss.move_cursor_down, { desc = '窗口/Pane 下移' })
            vim.keymap.set('n', '<C-k>', ss.move_cursor_up, { desc = '窗口/Pane 上移' })
            vim.keymap.set('n', '<C-l>', ss.move_cursor_right, { desc = '窗口/Pane 右移' })

            vim.keymap.set('t', '<C-h>', '<C-\\><C-N><C-h>', { desc = '终端模式左移' })
            vim.keymap.set('t', '<C-j>', '<C-\\><C-N><C-j>', { desc = '终端模式下移' })
            vim.keymap.set('t', '<C-k>', '<C-\\><C-N><C-k>', { desc = '终端模式上移' })
            vim.keymap.set('t', '<C-l>', '<C-\\><C-N><C-l>', { desc = '终端模式右移' })
        end,
    },
}
