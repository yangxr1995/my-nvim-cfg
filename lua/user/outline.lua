local status_ok, outline = pcall(require, "symbols-outline")
if not status_ok then
  print("symbols-outline 不存在")
  return
end

outline.setup()


