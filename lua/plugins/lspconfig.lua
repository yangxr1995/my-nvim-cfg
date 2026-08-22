return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
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
        -- LSP 快捷键
        vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, { desc = "显示提示文档" })
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "跳转到定义" })
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "跳转到声明" })
        vim.keymap.set("n", "go", vim.lsp.buf.type_definition, { desc = "跳转到类型定义" })
        vim.keymap.set("n", "grr", vim.lsp.buf.references, { desc = "跳转到引用" })
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "变量重命名" })
        vim.keymap.set("n", "<leader>aw", vim.lsp.buf.code_action, { desc = "打开修复建议" })

        -- 诊断信息配置
        vim.diagnostic.config({
            virtual_text = true,
            float = { severity_sort = true },
            severity_sort = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '',
                    [vim.diagnostic.severity.WARN] = '⚠',
                    [vim.diagnostic.severity.INFO] = '',
                    [vim.diagnostic.severity.HINT] = '',
                },
            },
        })

        -- 修复 hover 浮窗残留：内置实现把关闭事件（CursorMoved）绑定在打开浮窗时的
        -- 源 buffer 上，切换到其他 buffer 后旧浮窗永远不会自动关闭，
        -- 且在新 buffer 再按 K 会叠加新浮窗（内置按 buffer 号复用/关闭浮窗）。
        -- 因此进入 buffer 时，主动关闭所有属于其他 buffer 的 hover 浮窗。
        vim.api.nvim_create_autocmd('BufEnter', {
            group = vim.api.nvim_create_augroup('hover-float-cleanup', { clear = true }),
            callback = function(args)
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local src_buf = vim.w[win]['textDocument/hover']
                    -- 排除浮窗自身（聚焦浮窗时 BufEnter 的是浮窗自己的 scratch buffer）
                    if src_buf and src_buf ~= args.buf and vim.api.nvim_win_get_buf(win) ~= args.buf then
                        vim.api.nvim_win_close(win, true)
                    end
                end
            end,
        })

        local diag_enabled = true
        vim.keymap.set('n', '<leader>td', function()
            diag_enabled = not diag_enabled
            vim.diagnostic.config {
                underline = diag_enabled,
                virtual_text = diag_enabled,
                signs = diag_enabled,
                update_in_insert = diag_enabled,
            }
        end, { desc = 'LSP: 切换诊断显示' })

        -- LspAttach 回调
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
            callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)

                -- 浮动窗口显示诊断
                vim.keymap.set('n', '<leader>ld', function()
                    vim.diagnostic.open_float { source = true }
                end, { buffer = event.buf, desc = 'LSP: 显示诊断' })

                -- LSP 折叠
                if client and client:supports_method 'textDocument/foldingRange' then
                    local win = vim.api.nvim_get_current_win()
                    vim.wo[win]['foldexpr'] = 'v:lua.vim.lsp.foldexpr()'
                end

                -- Inlay Hint 切换
                if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                    vim.keymap.set('n', '<leader>th', function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                    end, { buffer = event.buf, desc = 'LSP: 切换 Inlay Hints' })
                end

                -- 光标下单词高亮
                if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                    local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
                    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                        buffer = event.buf,
                        group = highlight_augroup,
                        callback = vim.lsp.buf.document_highlight,
                    })
                    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                        buffer = event.buf,
                        group = highlight_augroup,
                        callback = vim.lsp.buf.clear_references,
                    })
                end

                -- LspDetach 清理
                vim.api.nvim_create_autocmd('LspDetach', {
                    group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
                    end,
                })
            end,
        })
    end,
}
