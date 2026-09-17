local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- This config manages plugins with lazy.nvim only, but catppuccin's integration
-- detection probes `vim.pack.get()`, whose lock-sync side effect force-creates
-- `site/pack/core/opt` on every startup. That empty dir makes both lazy.nvim's
-- and `vim.pack`'s checkhealth warn. Short-circuit `get` when vim.pack is
-- unused (no lockfile) so the directory is never created.
if vim.uv.fs_stat(vim.fn.stdpath("config") .. "/nvim-pack-lock.json") == nil then
  pcall(function()
    local pack = require("vim.pack")
    pack.get = function()
      return {}
    end
  end)
end


-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        -- import your plugins
        { import = "plugins" },
    },
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- automatically check for plugin updates
    checker = { enabled = false },
    change_detection = { enabled = false },
})
