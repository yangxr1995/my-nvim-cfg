return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons"
        },
        config = function()
            local status_ok, tree = pcall(require, "nvim-tree")
            if not status_ok then
                return
            end

            -- disable netrw at the very start of your init.lua
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            -- optionally enable 24-bit colour
            vim.opt.termguicolors = true

            -- 打开 command 快捷键映射
            local opts = { noremap = true, silent = true }
            local api = require "nvim-tree.api"
            vim.keymap.set('n', '<F2>', api.tree.toggle, opts)

            local function my_on_attach(bufnr)
                local api = require "nvim-tree.api"

                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end

                -- default mappings
                api.config.mappings.default_on_attach(bufnr)

                -- custom mappings
                vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent, opts('Up'))
                vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
            end

            tree.setup({
                sort = {
                    sorter = "case_sensitive",
                },
                view = {
                    width = 30,
                },
                renderer = {
                    group_empty = true,
                },
                filters = {
                    dotfiles = true,
                },
                on_attach = my_on_attach,
            })


            local status_ok, mini = pcall(require, "mini.files")
            if not status_ok then
                print("mini.files not exsit")
                return
            end

            mini.setup(
            -- No need to copy this inside `setup()`. Will be used automatically.
                {
                    -- Customization of shown content
                    content = {
                        -- Predicate for which file system entries to show
                        filter = nil,
                        -- What prefix to show to the left of file system entry
                        prefix = nil,
                        -- In which order to show file system entries
                        sort = nil,
                    },

                    -- Module mappings created only inside explorer.
                    -- Use `''` (empty string) to not create one.
                    mappings = {
                        close       = 'q',
                        go_in       = 'l',
                        go_in_plus  = 'L',
                        go_out      = 'h',
                        go_out_plus = 'H',
                        reset       = '<BS>',
                        reveal_cwd  = '@',
                        show_help   = 'g?',
                        synchronize = '=',
                        trim_left   = '<',
                        trim_right  = '>',
                    },

                    -- General options
                    options = {
                        -- Whether to delete permanently or move into module-specific trash
                        permanent_delete = true,
                        -- Whether to use for editing directories
                        use_as_default_explorer = true,
                    },

                    -- Customization of explorer windows
                    windows = {
                        -- Maximum number of windows to show side by side
                        max_number = math.huge,
                        -- Whether to show preview of file/directory under cursor
                        preview = true,
                        -- Width of focused window
                        width_focus = 50,
                        -- Width of non-focused window
                        width_nofocus = 15,
                        -- Width of preview window
                        width_preview = 25,
                    },
                }
            )
        end

    },
    {
        "echasnovski/mini.files",
        config = function()
            minifiles_toggle = function(...)
                if not MiniFiles.close() then MiniFiles.open(...) end
            end

            vim.keymap.set('n', '<F4>', '<cmd>lua minifiles_toggle()<CR>', {
                desc = "Search on current file"
            })
        end
    },
}
