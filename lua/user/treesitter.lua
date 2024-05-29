local status_ok, treesitter = pcall(require, "nvim-treesitter")
if not status_ok then
  print("treesitter 不存在")
  return
end

treesitter.setup {
  ensure_installed = {"c", "cpp", "bash", "python", "lua", "markdown_inline", "markdown", "regex"},
  sync_install = true, 
  ignore_install = { "" }, -- List of parsers to ignore installing
  highlight = {
    enable = true, -- false will disable the whole extension
    disable = { "" }, -- list of language that will be disabled
    additional_vim_regex_highlighting = true,
  },
  indent = { enable = true, disable = { "yaml" } },
}

local status_ok, treesitter_context = pcall(require, "treesitter-context")
if not status_ok then
  print("treesitter_context 不存在")
  return
end

treesitter_context.setup{
  enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20, -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}

local status_ok, comment = pcall(require, "ts_context_commentstring")
if not status_ok then
  print("ts_context_commentstring 不存在")
  return
end

comment.setup {
  enable_autocmd = false,
}

