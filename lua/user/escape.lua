local status_ok, escape = pcall(require, "better_escape")
if not status_ok then
  print("better_escape 不存在")
  return
end

escape.setup {
    mapping = {"jk", "kj"}, -- a table with mappings to use
    timeout = 250, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
    clear_empty_lines = false, -- clear line after escaping if there is only whitespace
    keys = "<Esc>", -- keys used for escaping, if it is a function will use the result everytime
    -- example(recommended)
    -- keys = function()
    --   return vim.api.nvim_win_get_cursor(0)[2] > 1 and '<esc>l' or '<esc>'
    -- end,
}
