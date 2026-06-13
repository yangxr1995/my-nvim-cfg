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

            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            vim.opt.termguicolors = true

            local function my_on_attach(bufnr)
                local api = require "nvim-tree.api"

                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end

                api.config.mappings.default_on_attach(bufnr)

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
        end
    },
    {
        "echasnovski/mini.files",
        keys = {
            { "<F4>", mode = "n", function () if not require("mini.files").close() then require("mini.files").open() end end, desc = "开启/关闭mini.files" },
        },
        config = function()
            require("mini.files").setup({
                content = {
                    filter = nil,
                    prefix = nil,
                    sort = nil,
                },
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
                options = {
                    permanent_delete = true,
                    use_as_default_explorer = true,
                },
                windows = {
                    max_number = math.huge,
                    preview = true,
                    width_focus = 50,
                    width_nofocus = 15,
                    width_preview = 25,
                },
            })
        end
    },
}
