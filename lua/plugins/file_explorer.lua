return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            {
                "nvim-tree/nvim-web-devicons",
                opt = true,
            }
        },
        keys = {
            { "<F2>", mode = "n", function () require("nvim-tree.api").tree.toggle() end, desc = "开启/关闭tree" }
        },
        lazy = true,
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
            -- local opts = { noremap = true, silent = true }
            -- local api = require "nvim-tree.api"
            -- vim.keymap.set('n', '<F2>', api.tree.toggle, opts)

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

            require 'nvim-web-devicons'.setup {
                -- your personnal icons can go here (to override)
                -- you can specify color or cterm_color instead of specifying both of them
                -- DevIcon will be appended to `name`
                override = {
                    zsh = {
                        icon = "",
                        color = "#428850",
                        cterm_color = "65",
                        name = "Zsh"
                    }
                },
                -- globally enable different highlight colors per icon (default to true)
                -- if set to false all icons will have the default icon's color
                color_icons = true,
                -- globally enable default icons (default to false)
                -- will get overriden by `get_icons` option
                default = true,
                -- globally enable "strict" selection of icons - icon will be looked up in
                -- different tables, first by filename, and if not found by extension; this
                -- prevents cases when file doesn't have any extension but still gets some icon
                -- because its name happened to match some extension (default to false)
                strict = true,
                -- set the light or dark variant manually, instead of relying on `background`
                -- (default to nil)
                variant = "light|dark",
                -- same as `override` but specifically for overrides by filename
                -- takes effect when `strict` is true
                override_by_filename = {
                    [".gitignore"] = {
                        icon = "",
                        color = "#f1502f",
                        name = "Gitignore"
                    }
                },
                -- same as `override` but specifically for overrides by extension
                -- takes effect when `strict` is true
                override_by_extension = {
                    ["log"] = {
                        icon = "",
                        color = "#81e043",
                        name = "Log"
                    }
                },
                -- same as `override` but specifically for operating system
                -- takes effect when `strict` is true
                override_by_operating_system = {
                    ["apple"] = {
                        icon = "",
                        color = "#A2AAAD",
                        cterm_color = "248",
                        name = "Apple",
                    },
                },
            }
        end

    },
    {
        "echasnovski/mini.files",
        keys = {
            { "<F4>", mode = "n", function () if not require("mini.files").close() then require("mini.files").open() end end, desc = "开启/关闭mini.files" },
        },
    },
}
