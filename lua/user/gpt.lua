local status_ok, gpt = pcall(require, "nvim-magic")
if not status_ok then
  print("nvim-magic 不存在")
  return
end

gpt.setup()
