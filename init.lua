-- disable netrw before plugins load (required by nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.options")
require("config.keymap")
require("config.lazy")
require("tts")
