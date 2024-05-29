local status_ok, surround = pcall(require, "nvim-surround")
if not status_ok then
  print("nvim-surround not exist")
  return
end

surround.setup {

--  key = {"cs", "ds", "ys"}
}
