return {
    "neovim/nvim-lspconfig",
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

        -- LspAttach 回调：仅在使用 lspconfig 时生效
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
            callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)

                -- 浮动窗口显示诊断
                vim.keymap.set('n', '<leader>ld', function()
                    vim.diagnostic.open_float { source = true }
                end, { buffer = event.buf, desc = 'LSP: 显示诊断' })

                -- 切换诊断显示
                vim.keymap.set('n', '<leader>td', (function()
                    local diag_status = 1
                    return function()
                        if diag_status == 1 then
                            diag_status = 0
                            vim.diagnostic.config { underline = false, virtual_text = false, signs = false, update_in_insert = false }
                        else
                            diag_status = 1
                            vim.diagnostic.config { underline = true, virtual_text = true, signs = true, update_in_insert = true }
                        end
                    end
                end)(), { buffer = event.buf, desc = 'LSP: 切换诊断显示' })

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
