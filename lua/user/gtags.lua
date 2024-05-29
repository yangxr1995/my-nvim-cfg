local status_ok, gtags = pcall(require, "telescope-gtags")
if not status_ok then
  print("没有找到 telescope-gtags")
  return
end

local opts = { noremap = true, silent = true }

vim.keymap.set('n', '<leader>gd', gtags.showDefinition, opts)
vim.keymap.set('n', '<leader>gr', gtags.showReference, opts)
gtags.setAutoIncUpdate(true)

-- keymap("n", "<leader>gd", "<cmd>lua require('telescope-gtags').showDefinition()<cr>", opts)
-- keymap("n", "<leader>gr", "<cmd>lua require('telescope-gtags').showReference()<cr>", opts)
-- nnoremap <leader>cg <cmd>lua require('telescope-gtags').showDefinition()<cr>
-- nnoremap <leader>cc <cmd>lua require('telescope-gtags').showReference()<cr>
-- nnoremap <leader>n <cmd>lua require('telescope-gtags').showCurrentFileTags()<cr>

-- gtags.setup()
