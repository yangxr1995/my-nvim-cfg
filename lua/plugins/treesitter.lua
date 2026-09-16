return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        priority = 1000,
        build = ":TSUpdate",
        config = function()
            -- main branch: install() is async and a no-op for installed parsers;
            -- parsers go to stdpath("data")/site.
            require("nvim-treesitter").install({
                "bash",
                "c",
                "cpp",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "vim",
                "vimdoc",
                "cmake",
            })

            -- Highlighting is provided by Neovim core via vim.treesitter.start();
            -- the main-branch rewrite no longer ships a highlight module.
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "bash", "c", "cpp", "lua", "markdown", "python", "vim", "vimdoc", "cmake" },
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end
    },
    {
        "HiPhish/rainbow-delimiters.nvim",
        ft = { "sh", "c", "cpp", "json", "lua", "python", "cmake", "cc" },
        config = function()
            local rainbow_delimiters = require 'rainbow-delimiters'
            vim.g.rainbow_delimiters = {
                strategy = {
                    [''] = rainbow_delimiters.strategy['global'],
                    vim = rainbow_delimiters.strategy['local'],
                },
                query = {
                    [''] = 'rainbow-delimiters',
                    lua = 'rainbow-blocks',
                },
                highlight = {
                    'RainbowDelimiterBlue',
                    'RainbowDelimiterYellow',
                    'RainbowDelimiterCyan',
                    'RainbowDelimiterViolet',
                    'RainbowDelimiterRed',
                    'RainbowDelimiterOrange',
                    'RainbowDelimiterGreen',
                },
            }
        end
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        ft = {"c", "cpp", "lua", "cmake", "json", "xml", "markdown"},
        config = function()
            local context = require("treesitter-context")
            context.setup({
                enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
                max_lines = 2,            -- How many lines the window should span. Values <= 0 mean no limit.
                min_window_height = 2,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                line_numbers = true,
                multiline_threshold = 5, -- Maximum number of lines to show for a single context
                trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
                -- Separator between context and content. Should be a single character string, like '-'.
                -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
                separator = nil,
                zindex = 20,     -- The Z-index of the context window
                on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
            }
            )
        end
    },
}
