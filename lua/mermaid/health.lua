-- Healthcheck for the mermaid rendering pipeline configured in
-- lua/plugins/mermaid.lua. Surface via :checkhealth mermaid.
local M = {}

local health = vim.health

local function has(bin)
  return vim.fn.executable(bin) == 1
end

-- mmdc must survive being run as root (Chromium sandbox). Our wrapper at
-- ~/.local/bin/mmdc injects the puppeteer config; a bare global install
-- crashes on every lint/render.
local function check_mmdc(reports)
  if not has("mmdc") then
    reports("mmdc: NOT FOUND", "Install it: npm install -g @mermaid-js/mermaid-cli")
    return
  end
  local exepath = vim.fn.exepath("mmdc")
  local is_wrapper = exepath:match("%.local/bin/mmdc$") ~= nil
  local out = vim.fn.system({ "mmdc", "--version" })
  if vim.v.shell_error ~= 0 then
    reports("mmdc: present but broken (" .. (out or "?"):gsub("%s+$", "") .. ")")
    return
  end
  if is_wrapper then
    health.ok("mmdc: " .. (out:gsub("%s+$", "")) .. " (sandbox wrapper: " .. exepath .. ")")
  elseif vim.uv.getuid() == 0 then
    reports(
      "mmdc " .. (out:gsub("%s+$", "")) .. " runs WITHOUT the root sandbox wrapper",
      "Running as root, Chromium will crash on every render/lint.",
      "Expected wrapper at ~/.local/bin/mmdc injecting -p ~/.config/mermaid/puppeteer.json"
    )
  else
    health.ok("mmdc: " .. (out:gsub("%s+$", "")))
  end
  local pup = vim.env.HOME .. "/.config/mermaid/puppeteer.json"
  if vim.uv.fs_stat(pup) then
    health.ok("puppeteer config: " .. pup)
  elseif vim.uv.getuid() == 0 then
    reports("puppeteer config missing: " .. pup, 'Create it: {"args":["--no-sandbox","--disable-setuid-sandbox"]}')
  end
end

M.check = function()
  -- Plugin core
  vim.health.start("mermaid.nvim: plugin")
  if vim.version.ge(vim.version(), "0.9.5") then
    health.ok("neovim >= 0.9.5 (" .. tostring(vim.version()) .. ")")
  else
    health.error("neovim >= 0.9.5 required, found " .. tostring(vim.version()))
  end
  if pcall(require, "mermaid") then
    health.ok("mermaid.nvim loaded")
  else
    health.error("mermaid.nvim not loadable (run :Lazy sync)")
  end
  if pcall(vim.treesitter.language.add, "mermaid") then
    health.ok("treesitter parser: mermaid")
  else
    health.warn("treesitter parser: mermaid NOT installed", "Run :TSInstall mermaid to enable syntax highlighting")
  end

  -- mmdc backs lint diagnostics and every PNG render
  vim.health.start("mermaid.nvim: mmdc (mermaid-cli)")
  local lint_on = pcall(require, "mermaid")
    and require("mermaid").config
      and require("mermaid").config.lint.enabled
  check_mmdc(lint_on and health.error or health.warn)

  -- Terminal render capability routes <leader>mm: "kitty" renders
  -- inline, "chafa" renders PNG via mmdc into the desktop viewer;
  -- "none" (no chafa, non-kitty terminal) fails both paths.
  vim.health.start("mermaid.nvim: render capability (<leader>mm)")
  if has("chafa") then
    local ver = vim.fn.system({ "chafa", "--version" }):match("version ([%d%.]+)") or "?"
    health.ok("chafa " .. ver .. " (<leader>mm renders PNG via mmdc and opens the desktop viewer)")
  else
    health.warn(
      "chafa NOT installed",
      "Outside kitty/iTerm2, <leader>mm has no working render path without chafa",
      "Install: apt install chafa"
    )
  end
  local ok_render, render_mod = pcall(require, "mermaid.render")
  if ok_render then
    local cap = render_mod.detect_capability()
    health.info("detected capability: " .. cap .. " (" .. render_mod.capability_label(cap) .. ")")
  end

  -- Desktop image viewer chain used by <leader>mr
  vim.health.start("mermaid.nvim: image viewer (<leader>mr)")
  if vim.env.DISPLAY or vim.env.WAYLAND_DISPLAY then
    if has("swayimg") then
      health.ok("swayimg (WSLg desktop viewer; press r inside to reload re-renders)")
    end
    if has("feh") then
      health.ok("feh (fallback, auto-reloads with --reload)")
    end
    if not has("swayimg") and not has("feh") then
      health.warn("no Linux viewer found", "Install one: apt install swayimg (or feh)")
    end
  else
    health.info("no DISPLAY/WAYLAND_DISPLAY; falling back to the Windows viewer")
  end
  local cmd_exe = "/mnt/c/Windows/System32/cmd.exe"
  if has("cmd.exe") or vim.uv.fs_stat(cmd_exe) then
    health.ok("cmd.exe interop (Windows viewer fallback / <leader>mo browser)")
  else
    health.warn("WSL interop unavailable; <leader>mo and the Windows viewer fallback need it")
  end

  -- md-render.nvim integration: <leader>mm inside render views maps the
  -- cursor back to the source buffer through session.source_line_map
  vim.health.start("mermaid.nvim: markdown integration (<leader>mm)")
  if pcall(require, "md-render") then
    health.ok("md-render.nvim available (mm works inside render views)")
  else
    health.info("md-render.nvim not loaded (mm still works in plain markdown buffers)")
  end
end

return M
