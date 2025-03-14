return {
    {
        "hrsh7th/nvim-cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        -- ft = { "sh", "c", "cpp", "json", "lua", "python", "cmake" },
        dependencies = {
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lua",
            "onsails/lspkind.nvim",
            "saadparwaiz1/cmp_luasnip",
            {
                "saadparwaiz1/cmp_luasnip",
                dependencies = {
                    "L3MON4D3/LuaSnip",
                    dependencies = {
                        "rafamadriz/friendly-snippets",
                    },
                    -- follow latest release.
                    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
                    -- install jsregexp (optional!).
                    build = "make install_jsregexp",
                    config = function()
                        require("luasnip.loaders.from_snipmate").lazy_load()
                        require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./snippets" } })
                    end
                }
            },
        },
        config = function()
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_snipmate").lazy_load({ path = { "~/.config/nvim/snippets" } })
            local luasnip = require("luasnip")
            local cmp = require 'cmp'
            --local lspkind = require('lspkind')
            cmp.setup {
                window = {
                    completion = {
                        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
                        col_offset = -3,
                        side_padding = 0,
                        border = 'rounded',
                        scrollbar = '║',
                    },
                    Documentation = {
                        border = nil,
                        scrollbar = '',
                    }
                },

                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = function(entry, vim_item)
                        local kind = require("lspkind").cmp_format({
                            mode = "symbol_text",
                            mode = "symbol",
                            maxwidth = 50,
                            ellipsis_char = '...',
                            symbol_map = { FittenCode = "", }
                        })(entry, vim_item)

                        local strings = vim.split(kind.kind, "%s", { trimempty = true })
                        kind.kind = " " .. (strings[1] or "") .. " "
                        kind.menu = "    (" .. (strings[2] or "") .. ")"

                        return kind
                    end,
                },
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                sources = cmp.config.sources {
                    { name = "fittencode" },
                    { name = "codeium" },
                    { name = 'luasnip' },
                    { name = 'nvim_lsp' },
                    { name = 'nvim_lua' },
                    { name = 'path' },
                    { name = "buffer" },
                },

                mapping = cmp.mapping.preset.insert {

                    ["<C-e>"] = cmp.mapping {
                        i = cmp.mapping.abort(),
                        c = cmp.mapping.close(),
                    },

                    ["<C-f>"] = cmp.mapping {
                        i = cmp.mapping.scroll_docs(1),
                        c = cmp.mapping.close(),
                    },
                    ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i" }),
                    ["<C-j>"] = cmp.mapping(function(fallback)
                        if cmp.visible() or cmp.cmdline() then
                            cmp.select_next_item()
                            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
                            -- they way you will only jump inside the snippet region
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s", "c" }),
                    ["<C-k>"] = cmp.mapping(function(fallback)
                        if cmp.visible() or cmp.cmdline() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s", "c" }),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expandable() then
                            luasnip.expand()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif check_backspace() then
                            fallback()
                        else
                            fallback()
                        end
                    end, {
                    "i",
                    "s",
                }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, {
                "i",
                "s",
            }),

        },

        experimental = {
            ghost_text = true,
        },
    }

    cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = 'buffer' },
        }
    })

    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = 'path' },
            { name = 'cmdline' }
        })
    })
    vim.fn.sign_define('DiagnosticSignError', { text = '🤣', texthl = 'DiagnosticSignError' })
    vim.fn.sign_define('DiagnosticSignWarn', { text = '🧐', texthl = 'DiagnosticSignWarn' })
    vim.fn.sign_define('DiagnosticSignInfo', { text = '🫠', texthl = 'DiagnosticSignInfo' })
    vim.fn.sign_define('DiagnosticSignHint', { text = '🤔', texthl = 'DiagnosticSignHint' })
end,
    },
    {
        "neovim/nvim-lspconfig",
        ft = { "sh", "c", "cc", "cpp", "json", "lua", "python", "cmake" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "folke/neoconf.nvim",
            "j-hui/fidget.nvim",
            "nvimdev/lspsaga.nvim",
            "folke/neodev.nvim",
        },
        config = function()
            local servers = {
                bashls = {
                    bashIde = {
                        enableSourceErrorDiagnostics = true,
                    }
                },
                clangd = {},
                jsonls = {},
                lua_ls = {
                    Lua = {
                        diagnostics = {
                            globals = {
                                'vim',
                                'require'
                            },
                        },
                        workspace = {
                            checkThirdParty = false,
                        },
                        completion = {
                            callSnippet = "Replace"
                        }
                    }

                },
                pyright = {},
                cmake = {
                    filetype = "cmake",
                },
            }
            local on_attach = function(_, bufnr)
                -- Enable completion triggered by <c-x><c-o>
                local nmap = function(keys, func, desc)
                    if desc then
                        desc = 'LSP: ' .. desc
                    end

                    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
                end

                nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                nmap('gd', require "telescope.builtin".lsp_definitions, '[G]oto [D]efinition')
                nmap('K', "<cmd>Lspsaga hover_doc<CR>", 'Hover Documentation')
                nmap('gi', require "telescope.builtin".lsp_implementations, '[G]oto [I]mplementation')
                -- nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
                nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
                nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
                nmap('<leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, '[W]orkspace [L]ist Folders')
                nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
                nmap('<leader>rn', "<cmd>Lspsaga rename ++project<cr>", '[R]e[n]ame')
                nmap('<leader>ca', "<cmd>Lspsaga code_action<CR>", '[C]ode [A]ction')
                nmap('<leader>da', require "telescope.builtin".diagnostics, '[D]i[A]gnostics')
                nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                -- nmap('gr', vim.lsp.buf.references, '[G]oto [R]eferences')
                --nmap("\\f", function()
                    --vim.lsp.buf.format { async = true }
                    --end, "[F]ormat code")
                    --nmap("\\f", "<cmd>GuardFmt<CR>", "[F]ormat code")
                end
                require("neoconf").setup()
                require("neodev").setup()
                require("fidget").setup()
                require("lspsaga").setup({
                    lightbulb = {
                        enble = false,
                        sign = false,
                    },
                    rename = {
                        keys = {
                            quit = '<esc>',
                        }
                    }
                })
                    require("mason").setup()
                    local capabilities = require('cmp_nvim_lsp').default_capabilities()
                    require("mason-lspconfig").setup({
                        ensure_installed = vim.tbl_keys(servers),
                        handlers = {
                            function(server_name) -- default handler (optional)
                                require("lspconfig")[server_name].setup {
                                    settings = servers[server_name],
                                    on_attach = on_attach,
                                    capabilities = capabilities,
                                }
                            end,
                        },
                    })

                    local signs = {
                        { name = "DiagnosticSignError", text = "" },
                        { name = "DiagnosticSignWarn", text = "" },
                        { name = "DiagnosticSignHint", text = "" },
                        { name = "DiagnosticSignInfo", text = "" },
                    }

                    local config = {
                        -- 诊断信息是否以virtual_text显示
                        virtual_text = false,
                        signs = {
                            active = signs,
                        },
                        update_in_insert = true,
                        underline = true,
                        severity_sort = true,
                        float = {
                            focusable = false,
                            style = "minimal",
                            border = "rounded",
                            source = "always",
                            header = "",
                            prefix = "",
                        },
                    }

                    vim.diagnostic.config(config)
                end
            },
            {
                'simrat39/symbols-outline.nvim',
                keys = {
                    { "<F3>", mode = "n", "<cmd>SymbolsOutline<CR>", desc = "打开/关闭符号表" }
                },
                config = function()
                    require("symbols-outline").setup({
                    })
                end
            }
        }
