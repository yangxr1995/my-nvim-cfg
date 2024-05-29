local status_ok, Flash = pcall(require, "flash")
if not status_ok then
  print("flash 找不到")
  return
end

