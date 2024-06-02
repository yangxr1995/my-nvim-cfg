local status_ok, Flash = pcall(require, "flash")
if not status_ok then
  print("flash 找不到")
  return
end

Flash.setup()

vim.keymap.set('n', 'f', function() require("flash").jump() end, {
    desc = "flash"
})
vim.keymap.set('x', 'f', function() require("flash").jump() end, {
    desc = "flash"
})
vim.keymap.set('o', 'f', function() require("flash").jump() end, {
    desc = "flash"
})
