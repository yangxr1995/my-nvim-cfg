-- 将 @this 位置引用追加到 opencode TUI 输入框（不发送），编辑完手动回车发送。
-- 原理：v2 服务端没有"预填输入框"的 API（v1 的 /tui/append-prompt 已移除，
-- 实测运行中服务的 openapi 无任何 tui 路由），输入框是 TUI 客户端本地状态，
-- 只能从 TUI 所在终端注入按键。注入通道按序尝试：
--   1. TUI 运行在 nvim 内嵌终端（term://opencode）→ chansend()
--   2. TUI 运行在 zellij pane → 通过 /proc/<pid>/{cmdline,cwd,environ} 找到
--      与 nvim 同目录的裸 `opencode` TUI 进程，取其 ZELLIJ_SESSION_NAME /
--      ZELLIJ_PANE_ID，执行 `zellij --session <s> action write-chars -p <pane>`

-- 读取 /proc/<pid>/environ 为 table
local function proc_environ(pid)
  local f = io.open(("/proc/%d/environ"):format(pid), "r")
  if not f then
    return {}
  end
  local data = f:read("*a")
  f:close()
  local env = {}
  for k, v in data:gmatch("([%w_]+)=([^%z]*)") do
    env[k] = v
  end
  return env
end

-- 找与 nvim 同 cwd 的裸 `opencode` TUI 进程（多个时取最新启动的），
-- 返回其 zellij 会话名与 pane id；找不到返回 nil
local function find_tui()
  local cwd = vim.fn.getcwd()
  local newest
  for _, pid_str in ipairs(vim.fn.systemlist("pgrep -x opencode")) do
    local pid = tonumber(pid_str)
    local f = pid and io.open(("/proc/%d/cmdline"):format(pid), "r")
    if f then
      -- 仅匹配裸 `opencode`（排除 `opencode serve --service` 等子命令进程）
      local cmd = f:read("*a"):gsub("%z", " ")
      f:close()
      if cmd:match("^opencode%s*$") and vim.uv.fs_readlink(("/proc/%d/cwd"):format(pid)) == cwd then
        newest = pid
      end
    end
  end
  if not newest then
    return nil
  end
  local env = proc_environ(newest)
  if env.ZELLIJ_PANE_ID and env.ZELLIJ_SESSION_NAME then
    return { session = env.ZELLIJ_SESSION_NAME, pane = env.ZELLIJ_PANE_ID }
  end
  return nil
end

local function append_to_opencode_input()
  _G.opencode_append_operator = function(kind) ---@param kind "char" | "line" | "block"
    local start_pos = vim.api.nvim_buf_get_mark(0, "[")
    local end_pos = vim.api.nvim_buf_get_mark(0, "]")
    if start_pos[1] > end_pos[1] or (start_pos[1] == end_pos[1] and start_pos[2] > end_pos[2]) then
      start_pos, end_pos = end_pos, start_pos
    end

    require("opencode.server.discovery")
      .get()
      :next(function(server)
        -- 借用插件的上下文机制生成与原来相同的引用文本（无副作用，仅渲染）
        local context = require("opencode.context").new(server, {
          from = { start_pos[1], start_pos[2] },
          to = { end_pos[1], end_pos[2] },
          kind = kind,
        })
        local ref = context:render("@this ").output:plaintext()
        context:clear()
        if type(ref) ~= "string" or ref == "" then
          return
        end
        ref = ref:gsub("\n", " ")

        -- 路径 1：TUI 在 nvim 内嵌终端
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local chan = vim.b[buf].terminal_job_id
          if chan and vim.api.nvim_buf_get_name(buf):find("^term://.*opencode") then
            vim.fn.chansend(chan, ref)
            -- 跳到 TUI 窗口并进入终端插入模式，方便直接编辑后回车
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_buf(win) == buf then
                vim.api.nvim_set_current_win(win)
                vim.cmd("startinsert")
                break
              end
            end
            return
          end
        end

        -- 路径 2：TUI 在 zellij pane
        local tui = find_tui()
        if tui then
          vim.system({ "zellij", "--session", tui.session, "action", "write-chars", "-p", tui.pane, ref }, nil, function(r)
            if r.code ~= 0 then
              vim.schedule(function()
                vim.notify(
                  ("zellij write-chars 失败(code %d): %s"):format(r.code, r.stderr or ""),
                  vim.log.levels.ERROR,
                  { title = "opencode" }
                )
              end)
            end
          end)
          vim.notify(
            ("已追加到 zellij 会话 `%s` 的 pane %s"):format(tui.session, tui.pane),
            vim.log.levels.INFO,
            { title = "opencode" }
          )
          return
        end

        vim.notify(
          "未找到可注入的 opencode TUI（需运行在 nvim 内嵌终端或 zellij pane 中，且 cwd 与 nvim 相同）",
          vim.log.levels.WARN,
          { title = "opencode" }
        )
      end)
      :catch(function(err)
        vim.notify(tostring(err), vim.log.levels.ERROR, { title = "opencode" })
      end)
  end

  vim.o.operatorfunc = "v:lua.opencode_append_operator"
  return "g@"
end

return {
  "nickjvandyke/opencode.nvim",
  -- v2 默认支持 OpenCode v2（service.json + /api/*）。
  -- 如需 v1 兼容，取消注释下一行：
  -- version = "*",
  dependencies = {
    -- `ask()` 和 `select()` 推荐使用。
    -- `snacks` provider 必需。
    ---@module 'snacks' <- 加载 `snacks.nvim` 类型以提供配置智能提示。
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  keys = {
    { "<leader>oa", function() require("opencode").ask("@this: ") end,   mode = { "n", "x" }, desc = "Ask opencode…" },
    { "<leader>os", function() require("opencode").select() end,         mode = { "n", "x" }, desc = "Execute opencode action…" },
    { "go",          function() return append_to_opencode_input() end,      mode = { "n", "x" }, desc = "Append range to opencode input", expr = true },
    { "goo",         function() return append_to_opencode_input() .. "_" end, mode = "n",          desc = "Append line to opencode input",   expr = true },
    { "+",           "<C-a>",                                               mode = "n",          desc = "Increment under cursor", noremap = true },
    { "-",           "<C-x>",                                               mode = "n",          desc = "Decrement under cursor", noremap = true },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- 你的配置（如有）— 参见 `lua/opencode/config.lua`，或对类型/字段使用 "goto definition"。
    }

    -- `opts.events.reload` 所必需。
    vim.o.autoread = true
  end,
}
