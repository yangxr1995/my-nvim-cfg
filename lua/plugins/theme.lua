return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            vim.cmd.colorscheme('catppuccin-mocha')
            -- CursorLine 高亮覆盖
            vim.cmd([[highlight CursorLine cterm=bold,underline ctermbg=235 guibg=#444444]])
        end
    },
    -- 备用主题（lazy 加载，仅 :colorscheme 时激活）
    { 'sainnhe/sonokai', lazy = true },
    { 'lunarvim/darkplus.nvim', lazy = true },
}
