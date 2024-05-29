local status_ok, hl_md = pcall(require, "hl-mdcodeblock")
if not status_ok then
  print("hl-mdcodeblock 找不到")
  return
end

hl_md.setup {
  hl_group = "MDCodeBlock",   -- default highlight group
  events = {                  -- refresh event
    "FileChangedShellPost",
    "Syntax",
    "TextChanged",
    "TextChangedI",
    "InsertLeave",
    "WinScrolled",
    "BufEnter",
  },
  padding_right = 4,          -- always append 4 space at lineend
  timer_delay = 20,           -- refresh delay(ms)
  query_by_ft = {             -- special parser query by filetype
    markdown = {            -- filetype
      'markdown',         -- parser
      '(fenced_code_block) @codeblock', -- query
    },
    rmd = {                 -- filetype
      'markdown',         -- parser
      '(fenced_code_block) @codeblock', -- query
    },
  },
  minumum_len = 100,          -- minimum len to highlight (number | function)
  -- minumum_len = function () return math.max(math.floor(vim.api.nvim_win_get_width(0) * 0.8), 100) end
}
