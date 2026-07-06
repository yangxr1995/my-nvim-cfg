return {
  "nickjvandyke/opencode.nvim",
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
  end,
}
