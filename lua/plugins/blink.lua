return  {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	{
		'saghen/blink.cmp',
		event = {'BufReadPost', 'BufNewFile'},
		dependencies = {{ 'rafamadriz/friendly-snippets' }, {'xzbdmw/colorful-menu.nvim', opts = {} }},

		version = '1.6',
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-s: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = { preset = 'none' ,
			['<C-s>'] = { 'show', 'show_documentation', 'hide_documentation' },
			['<C-e>'] = { 'hide' },
			['<C-y>'] = { 'select_and_accept' },

			['<Up>'] = { 'select_prev', 'fallback' },
			['<Down>'] = { 'select_next', 'fallback' },
			['<C-k>'] = { 'select_prev', 'fallback_to_mappings' },
			['<C-j>'] = { 'select_next', 'fallback_to_mappings' },

			['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
			['<C-d>'] = { 'scroll_documentation_down', 'fallback' },

			['<Tab>'] = { 'snippet_forward', 'fallback' },
			['<S-Tab>'] = { 'snippet_backward', 'fallback' },

			-- ['<C-l>'] = { 'show_signature', 'hide_signature', 'fallback' },
		},

		signature = {
			enabled = true,
		},

		cmdline = {
			completion = {
				menu = {
					auto_show = true,
				},
			},
		          keymap = {
		              ['<Tab>'] = {'show', 'accept'},
		              ['<C-y>'] = { 'select_and_accept' },
		              ['<C-k>'] = { 'select_prev', 'fallback_to_mappings' },
		              ['<C-j>'] = { 'select_next', 'fallback_to_mappings' },
		          },
		},

		appearance = {
			nerd_font_variant = 'mono'
		},

		completion = {
			documentation = { auto_show = true } ,
			menu = {
				draw = {
					-- We don't need label_description now because label and label_description are already
					-- combined together in label by colorful-menu.nvim.
					columns = { { "kind_icon" }, { "label", gap = 1 } },
					components = {
						label = {
							text = function(ctx)
								return require("colorful-menu").blink_components_text(ctx)
							end,
							highlight = function(ctx)
								return require("colorful-menu").blink_components_highlight(ctx)
							end,
						},
					},
				},
			},
		},

		sources = {
			default = { "lazydev", "path", "snippets", "buffer", "lsp" },
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 3,
				},
                path = {
                    score_offset = 1,
                },
                snippets = {
                    score_offset = 10,
                },
                buffer = {
                    score_offset = 2,
                },
                lsp = {
                    score_offset = 4,
                },
			},
		},

		fuzzy = { implementation = "prefer_rust_with_warning" },
    },
	opts_extend = { "sources.default" }
},

}
