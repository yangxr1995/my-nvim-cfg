local status_ok, wilder = pcall(require, "wilder")
if not status_ok then
  print("wilder 找不到")
  return
end

wilder.setup({modes = {':', '/', '?'}})

wilder.set_option('renderer', wilder.popupmenu_renderer(
  wilder.popupmenu_palette_theme({
    -- 'single', 'double', 'rounded' or 'solid'
    -- can also be a list of 8 characters, see :h wilder#popupmenu_palette_theme() for more details
    border = 'rounded',
    max_height = '75%',      -- max height of the palette
    min_height = 0,          -- set to the same as 'max_height' for a fixed height window
    prompt_position = 'top', -- 'top' or 'bottom' to set the location of the prompt
    reverse = 0,             -- set to 1 to reverse the order of the list, use in combination with 'prompt_position'
  })
))

vim.keymap.set('c', '<tab>', '<cmd>lua require("wilder").next()<CR>', { desc = "next command"})
vim.keymap.set('c', '<up>', '<cmd>lua require("wilder").previous()<CR>', { desc = "previous command"})
vim.keymap.set('c', '<down>', '<cmd>lua require("wilder").next()<CR>', { desc = "next command "})
vim.keymap.set('c', '<C-k>', '<cmd>lua require("wilder").previous()<CR>', { desc = "previous command"})
vim.keymap.set('c', '<C-j>', '<cmd>lua require("wilder").next()<CR>', { desc = "next command"})

-- local gradient = {
--   '#f4468f', '#fd4a85', '#ff507a', '#ff566f', '#ff5e63',
--   '#ff6658', '#ff704e', '#ff7a45', '#ff843d', '#ff9036',
--   '#f89b31', '#efa72f', '#e6b32e', '#dcbe30', '#d2c934',
--   '#c8d43a', '#bfde43', '#b6e84e', '#aff05b'
-- }
--
-- for i, fg in ipairs(gradient) do
--   gradient[i] = wilder.make_hl('WilderGradient' .. i, 'Pmenu', {{a = 1}, {a = 1}, {foreground = fg}})
-- end
--
-- wilder.set_option('renderer', wilder.popupmenu_renderer({
--   highlights = {
--     gradient = gradient, -- must be set
--     -- selected_gradient key can be set to apply gradient highlighting for the selected candidate.
--   },
--   highlighter = wilder.highlighter_with_gradient({
--     wilder.basic_highlighter(), -- or wilder.lua_fzy_highlighter(),
--   }),
-- }))
