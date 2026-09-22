return {
  "nickjvandyke/opencode.nvim",
  -- Last v1-compatible commit (includes directory-routing fix #239).
  -- main migrated to OpenCode v2 (service.json + /api/*), incompatible with
  -- installed opencode CLI 1.18.32 (v1: process scan + /session).
  -- Do NOT use version = "*": a v2.0.0 tag exists and would be selected.
  commit = "71fb506ef1898048bc548668f31f495ad6c29453",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  keys = {
    { "<leader>oa", function() require("opencode").ask("@this: ", { submit = true }) end, mode = { "n", "x" }, desc = "Ask opencode…" },
    { "<leader>os", function() require("opencode").select() end,                          mode = { "n", "x" }, desc = "Execute opencode action…" },
    { "<leader>ot", function() require("opencode").toggle() end,                          mode = { "n", "t" }, desc = "Toggle opencode" },
    { "go",         function() return require("opencode").operator("@this ") end,         mode = { "n", "x" }, desc = "Add range to opencode", expr = true },
    { "goo",        function() return require("opencode").operator("@this ") .. "_" end,  mode = "n",          desc = "Add line to opencode",   expr = true },
    { "<M-u>",      function() require("opencode").command("session.half.page.up") end,   mode = "n",          desc = "Scroll opencode up" },
    { "<M-d>",      function() require("opencode").command("session.half.page.down") end, mode = "n",          desc = "Scroll opencode down" },
    { "+",          "<C-a>",                                                               mode = "n",          desc = "Increment under cursor", noremap = true },
    { "-",          "<C-x>",                                                               mode = "n",          desc = "Decrement under cursor", noremap = true },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Workaround for upstream opencode.nvim bug.
    -- server/init.lua:349 passes `self.disconnect` (field access, no binding)
    -- to `vim.schedule_wrap` as the heartbeat timer callback. When the timer
    -- fires (heartbeat timeout: server gone / killed / network drop), `self`
    -- is nil and `Server:disconnect()` errors at its first index access.
    -- Wrap with nil-safe no-op; stays as a harmless no-op once upstream fixes it.
    local Server = require("opencode.server")
    local orig_disconnect = Server.disconnect
    Server.disconnect = function(self, ...)
      if self == nil then
        return
      end
      return orig_disconnect(self, ...)
    end
  end,
}
