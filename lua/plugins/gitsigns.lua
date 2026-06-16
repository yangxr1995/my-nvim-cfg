return {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    config = function()
        require("gitsigns").setup {
            signs = {
                add          = { text = "┃" },
                change       = { text = "┃" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
                untracked    = { text = "┆" },
            },
            signs_staged = {
                add          = { text = "┃" },
                change       = { text = "┃" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
                untracked    = { text = "┆" },
            },
            signs_staged_enable = true,
            signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
            numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
            linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
            watch_gitdir = {
                follow_files = true,
            },
            auto_attach = true,
            attach_to_untracked = false,
            current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                delay = 1000,
                ignore_whitespace = false,
                virt_text_priority = 100,
                use_focus = true,
            },
            current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
            sign_priority = 6,
            update_debounce = 100,
            max_file_length = 40000, -- Disable if file is longer than this (in lines)
            preview_config = {
                style = 'minimal',
                relative = 'cursor',
                row = 0,
                col = 1,
            },
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                vim.keymap.set("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end, { buffer = bufnr, desc = "下一个 hunk" })

                vim.keymap.set("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end, { buffer = bufnr, desc = "上一个 hunk" })

                vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk,
                    { buffer = bufnr, desc = "暂存 hunk" })
                vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk,
                    { buffer = bufnr, desc = "重置 hunk" })
                vim.keymap.set("v", "<leader>hs", function()
                    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { buffer = bufnr, desc = "暂存选中 hunk" })
                vim.keymap.set("v", "<leader>hr", function()
                    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { buffer = bufnr, desc = "重置选中 hunk" })

                vim.keymap.set("n", "<leader>hS", gitsigns.stage_buffer,
                    { buffer = bufnr, desc = "暂存整个文件" })
                vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer,
                    { buffer = bufnr, desc = "重置整个文件" })
                vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk,
                    { buffer = bufnr, desc = "预览 hunk diff" })

                vim.keymap.set("n", "<leader>hb", function()
                    gitsigns.blame_line({ full = true })
                end, { buffer = bufnr, desc = "查看行 blame" })
                vim.keymap.set("n", "<leader>hd", gitsigns.diffthis,
                    { buffer = bufnr, desc = "对比当前文件" })
                vim.keymap.set("n", "<leader>hD", function()
                    gitsigns.diffthis("~")
                end, { buffer = bufnr, desc = "对比当前文件（index）" })

                vim.keymap.set("n", "<leader>tb", gitsigns.toggle_current_line_blame,
                    { buffer = bufnr, desc = "切换行 blame" })
                vim.keymap.set("n", "<leader>tw", gitsigns.toggle_word_diff,
                    { buffer = bufnr, desc = "切换 word diff" })
                vim.keymap.set("n", "<leader>tD", gitsigns.toggle_deleted,
                    { buffer = bufnr, desc = "切换删除行显示" })

                vim.keymap.set({ "o", "x" }, "ih", gitsigns.select_hunk,
                    { buffer = bufnr, desc = "选中 hunk 文本对象" })
                vim.keymap.set("n", "<leader>ih", function()
                    vim.cmd("normal! vih")
                end, { buffer = bufnr, desc = "选中当前 hunk" })

                vim.keymap.set("n", "<leader>hq", gitsigns.setqflist,
                    { buffer = bufnr, desc = "当前文件 hunks 到 quickfix" })
                vim.keymap.set("n", "<leader>hQ", function()
                    gitsigns.setqflist("all")
                end, { buffer = bufnr, desc = "所有文件 hunks 到 quickfix" })
            end,
        }
    end,
}
