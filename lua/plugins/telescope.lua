
return {
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-lua/popup.nvim',
            'nvim-telescope/telescope-file-browser.nvim',
            'nvim-telescope/telescope-media-files.nvim',
            'nvim-telescope/telescope-symbols.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
        },
        keys = {
            { 'rr', function() require('telescope.builtin').live_grep() end ,  desc = "live grep"  },
            { 'rf', function() require('telescope.builtin').find_files() end ,  desc = "find files"  },
            { 'rs', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end ,  desc = "find lsp symbols"  },
        },
        lazy = true,

        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            telescope.load_extension('media_files')
            telescope.setup {}

            telescope.setup {
                defaults = {
                  layout_strategy = 'cursor',
                  layout_config = { height = 0.90 , width = 0.98 },

                    prompt_prefix = " ",
                    selection_caret = " ",
                    path_display = { "smart" },

                    mappings = {
                        i = {
                            ["<C-n>"] = actions.cycle_history_next,
                            ["<C-p>"] = actions.cycle_history_prev,

                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,

                            ["<C-c>"] = actions.close,

                            ["<Down>"] = actions.move_selection_next,
                            ["<Up>"] = actions.move_selection_previous,

                            ["<CR>"] = actions.select_default,
                            ["<C-x>"] = actions.select_horizontal,
                            ["<C-v>"] = actions.select_vertical,
                            ["<C-t>"] = actions.select_tab,

                            ["<C-u>"] = actions.preview_scrolling_up,
                            ["<C-d>"] = actions.preview_scrolling_down,

                            ["<PageUp>"] = actions.results_scrolling_up,
                            ["<PageDown>"] = actions.results_scrolling_down,

                            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                            ["<C-l>"] = actions.complete_tag,
                            ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
                        },

                        n = {
                            ["<esc>"] = actions.close,
                            ["<CR>"] = actions.select_default,
                            ["<C-x>"] = actions.select_horizontal,
                            ["<C-v>"] = actions.select_vertical,
                            ["<C-t>"] = actions.select_tab,

                            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

                            ["j"] = actions.move_selection_next,
                            ["k"] = actions.move_selection_previous,
                            ["H"] = actions.move_to_top,
                            ["M"] = actions.move_to_middle,
                            ["L"] = actions.move_to_bottom,

                            ["<Down>"] = actions.move_selection_next,
                            ["<Up>"] = actions.move_selection_previous,
                            ["gg"] = actions.move_to_top,
                            ["G"] = actions.move_to_bottom,

                            ["<C-u>"] = actions.preview_scrolling_up,
                            ["<C-d>"] = actions.preview_scrolling_down,

                            ["<PageUp>"] = actions.results_scrolling_up,
                            ["<PageDown>"] = actions.results_scrolling_down,

                            ["?"] = actions.which_key,
                        },
                    },
                },

                extensions = {
                    media_files = {
                        -- filetypes whitelist
                        -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
                        filetypes = { "png", "webp", "jpg", "jpeg" },
                        find_cmd = "rg" -- find command (defaults to `fd`)
                    },
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
                    }
                },


            }
        end
    },
    {

        "ivechan/telescope-gtags",
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
        keys = {
            { "<leader>gd", mode = "n", function () require("telescope-gtags").showDefinition() end, desc = "gtags查找定义" },
            { "<leader>gr", mode = "n", function () require("telescope-gtags").showReference() end, desc = "gtags查找引用" }
        },
        lazy = true,
        config = function()
            local status_ok, gtags = pcall(require, "telescope-gtags")
            if not status_ok then
                print("没有找到 telescope-gtags")
                return
            end

            -- local opts = { noremap = true, silent = true }
            -- vim.keymap.set('n', '<leader>gd', gtags.showDefinition, opts)
            -- vim.keymap.set('n', '<leader>gr', gtags.showReference, opts)
            gtags.setAutoIncUpdate(true)
        end

    },
    {
        'folke/todo-comments.nvim',
        ft = {"c", "cpp", "h", "sh", "lua"},
        -- event = "InsertEnter",
        opts = {
                    signs = true, -- show icons in the signs column
                    sign_priority = 8, -- sign priority
                    -- keywords recognized as todo comments
                    keywords = {
                        FIX = {
                            icon = " ", -- icon used for the sign, and in search results
                            color = "error", -- can be a hex color, or a named color (see below)
                            alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
                            -- signs = false, -- configure signs for some keywords individually
                        },
                        TODO = { icon = " ", color = "info" },
                        HACK = { icon = " ", color = "warning" },
                        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
                    },
                    gui_style = {
                        fg = "NONE", -- The gui style to use for the fg highlight group.
                        bg = "BOLD", -- The gui style to use for the bg highlight group.
                    },
                    merge_keywords = true, -- when true, custom keywords will be merged with the defaults
                    -- highlighting of the line containing the todo comment
                    -- * before: highlights before the keyword (typically comment characters)
                    -- * keyword: highlights of the keyword
                    -- * after: highlights after the keyword (todo text)
                    highlight = {
                        multiline = true, -- enable multine todo comments
                        multiline_pattern = "^.", -- lua pattern to match the next multiline from the start of the matched keyword
                        multiline_context = 10, -- extra lines that will be re-evaluated when changing a line
                        before = "", -- "fg" or "bg" or empty
                        keyword = "wide", -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
                        after = "fg", -- "fg" or "bg" or empty
                        pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns, used for highlighting (vim regex)
                        comments_only = true, -- uses treesitter to match keywords in comments only
                        max_line_len = 400, -- ignore lines longer than this
                        exclude = {}, -- list of file types to exclude highlighting
                    },
                    -- list of named colors where we try to extract the guifg from the
                    -- list of highlight groups or use the hex color if hl not found as a fallback
                    colors = {
                        error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                        warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
                        info = { "DiagnosticInfo", "#2563EB" },
                        hint = { "DiagnosticHint", "#10B981" },
                        default = { "Identifier", "#7C3AED" },
                        test = { "Identifier", "#FF00FF" }
                    },
                    search = {
                        command = "rg",
                        args = {
                            "--color=never",
                            "--no-heading",
                            "--with-filename",
                            "--line-number",
                            "--column",
                        },
                        -- regex that will be used to match keywords.
                        -- don't replace the (KEYWORDS) placeholder
                        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
                        -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
                    },
        },
    }
}
