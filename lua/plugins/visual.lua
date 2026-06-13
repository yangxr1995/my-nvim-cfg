return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = function(_, opts)
            return require("indent-rainbowline").make_opts(opts, {
                color_transparency = 0.15,
                colors = { 0xff0000, 0x00ff00, 0x0000ff, },
            })
        end,
        dependencies = {
            "TheGLander/indent-rainbowline.nvim",
        },
    },
    {
        'yamatsum/nvim-cursorline',
        config = function()
            require('nvim-cursorline').setup {
                cursorline = {
                    enable = false,
                    timeout = 1000,
                    number = false,
                },
                cursorword = {
                    enable = false,
                    min_length = 3,
                    hl = { underline = true },
                }
            }
        end
    },
    {
        'xiyaowong/transparent.nvim',
        event = "VeryLazy",
        config = function()
            require("transparent").setup({
                groups = {
                    'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
                    'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
                    'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
                    'SignColumn', 'CursorLine', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
                    'EndOfBuffer',
                },
                extra_groups = {},
                exclude_groups = {},
            })
        end
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            require("which-key").setup {}
        end
    },
    {
        'kevinhwang91/nvim-bqf', ft = 'qf'
    },
    {
        'rmagatti/goto-preview',
        keys = {
            { "gpd", mode = "n", function() require("goto-preview").goto_preview_definition() end, desc = "预览定义" },
            { "gpi", mode = "n", function() require("goto-preview").goto_preview_implementation() end, desc = "预览实现" },
            { "gpt", mode = "n", function() require("goto-preview").goto_preview_type_definition() end, desc = "预览类型定义" },
        },
        config = function()
            local status_ok, goto_pre = pcall(require, "goto-preview")
            if not status_ok then
                return
            end

            local themes_ok, themes = pcall(require, "telescope.themes")

            goto_pre.setup {
                width = 120,
                height = 15,
                border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" },
                default_mappings = false,
                debug = false,
                opacity = nil,
                resizing_mappings = false,
                post_open_hook = nil,
                post_close_hook = nil,
                references = {
                    telescope = themes_ok and themes.get_dropdown({ hide_preview = false }) or nil,
                },
                focus_on_open = true,
                dismiss_on_move = false,
                force_close = true,
                bufhidden = "wipe",
                stack_floating_preview_windows = true,
                preview_window_title = { enable = true, position = "left" },
            }
        end
    },
}
