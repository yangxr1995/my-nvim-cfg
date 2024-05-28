local status_ok, buffer = pcall(require, "bufferline")
if not status_ok then
  print("没有找到 buffer-line")
  return
end

buffer.setup()

