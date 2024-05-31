local status_ok, gpt = pcall(require, "nvim-magic")
if not status_ok then
  print("nvim-magic 不存在")
  return
end

gpt.setup()


vim.keymap.set('v', '<leader>gc', 
'<cmd>lua require("nvim-magic.flows").suggest_chat(require("nvim-magic").backends.default)<CR>', 
{
    desc = "Chat, ask questions, keep the context"
})

vim.keymap.set('v', '<leader>ga', 
'<cmd>lua require("nvim-magic.flows").append_completion(require("nvim-magic").backends.default)<CR>', 
{
    desc = "Fetch and append completion"
})

vim.keymap.set('v', '<leader>gd', 
'<cmd>lua require("nvim-magic.flows").suggest_docstring(require("nvim-magic").backends.default)<CR>', 
{
    desc = "Generate a docstring"
})

vim.keymap.set('v', '<leader>gs', 
'<cmd>lua require("nvim-magic.flows").suggest_alteration(require("nvim-magic").backends.default)<CR>', 
{
    desc = "Ask for an alteration to the selected text"
})

vim.keymap.set('v', '<leader>gr', 
'<cmd>lua require("nvim-magic.flows").suggest_chat_reset(require("nvim-magic").backends.default)<CR>', 
{
    desc = "Chat, reset history, start over"
})

vim.keymap.set('v', '<leader>gq', 
'<cmd>lua require("nvim-magic.flows").content_chat_qa(require("nvim-magic").backends.default)<CR>', 
{
    desc = "Ask questions about a document (requires active chat window and cursor placed in the document of interest)"
})

