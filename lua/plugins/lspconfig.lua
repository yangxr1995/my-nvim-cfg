return {
    "neovim/nvim-lspconfig",
    dependencies = {
        -- 通过mason来自动安装语言服务器并启用
        { "mason-org/mason.nvim", opts = {} },
        {
            "mason-org/mason-lspconfig.nvim",
            opts = {
                ensure_installed = {
                    "clangd",
                    "neocmake",
                    "bashls",
                    "lua_ls",
                    "marksman",
                },
                automatic_enable = {
                    exclude = {},
                },
            },
        },
    },
    config = function()
        -- 快捷键的映射
        vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, opts)         -- <space>h显示提示文档
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)           -- gd跳转到定义
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)          -- gD跳转到声明(例如c语言中的头文件中的原型、一个变量的extern声明)
        vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)      -- go跳转到变量类型定义的位置(例如一些自定义类型)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)           -- gr跳转到引用了对应变量或函数的位置
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)       -- <space>rn变量重命名
        -- vim.keymap.set("n", "<leader>aw", vim.lsp.buf.code_action, opts)  -- <space>aw可以在出现警告或错误的地方打开建议的修复方法
        -- vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- <space>d浮动窗口显示所在行警告或错误信息
        -- vim.keymap.set("n", "<leader>-", vim.diagnostic.goto_prev, opts)  -- <space>-跳转到上一处警告或错误的地方
        -- vim.keymap.set("n", "<leader>=", vim.diagnostic.goto_next, opts)  -- <space>+跳转到下一处警告或错误的地方
        -- vim.keymap.set({ 'n', 'x' }, '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts) -- <space>f进行代码格式化

        -- 诊断信息的图标
        vim.diagnostic.config({
            virtual_text = true,
            float = {severity_sort = true},
            severity_sort = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '',
                    [vim.diagnostic.severity.WARN] = '⚠',
                    [vim.diagnostic.severity.INFO] = '',
                    [vim.diagnostic.severity.HINT] = '',
                },
            },
        })
    end,
}
