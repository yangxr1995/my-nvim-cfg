-- tts.lua: local TTS, synthesis/playback handled by tools/tts_speak_rapid.py

-- 默认配置
local config = {
    -- "kokoro" (default) or "moss", see BACKENDS in tools/tts_speak_rapid.py
    backend = "kokoro",
    -- backend = "moss",
    -- python interpreter with rapidtts installed
    python = "/root/test/tts/.venv/bin/python",
}

local rapid_script = vim.fn.stdpath("config") .. "/tools/tts_speak_rapid.py"
local last_wav = vim.fn.stdpath("cache") .. "/tts/last_audio.wav"
local current_job = nil
local stopped_jobs = {} -- 已被主动 jobstop 的 job id，退出时不报警

-- 设置配置
local function setup(opts)
    config = vim.tbl_extend("force", config, opts or {})
end

local function stop_job()
    if current_job then
        -- 标记为主动停止，on_exit 时跳过报警（jobstop 会导致非零退出码）
        stopped_jobs[current_job] = true
        vim.fn.jobstop(current_job)
        current_job = nil
    end
end

local function start_job(cmd, text)
    stop_job()
    local stderr_lines = {}
    current_job = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            for _, line in ipairs(data or {}) do
                -- 脚本用 [tts] 前缀报告阶段(生成/播放), 覆盖式回显不刷屏
                local msg = line:match("^%[tts%] (.+)$")
                if msg then
                    vim.api.nvim_echo({ { "tts: " .. msg, "Normal" } }, false, {})
                end
            end
        end,
        on_stderr = function(_, data)
            for _, line in ipairs(data or {}) do
                if line ~= "" then
                    -- 滑动窗口只保留末尾 5 行：真实错误在 stderr 末尾，前面是库的日志噪音
                    if #stderr_lines >= 5 then
                        table.remove(stderr_lines, 1)
                    end
                    -- 去掉 colorlog 的 ANSI 颜色码，避免通知里出现 ^[[32m 乱码
                    local clean = line:gsub("\27%[[%d;]*m", "")
                    table.insert(stderr_lines, clean)
                end
            end
        end,
        on_exit = function(job_id, exit_code)
            if stopped_jobs[job_id] then
                stopped_jobs[job_id] = nil
            elseif exit_code ~= 0 then
                -- surface script diagnostics (e.g. missing backend install hints)
                local detail = #stderr_lines > 0 and table.concat(stderr_lines, "\n")
                    or ("exited with code " .. exit_code)
                vim.notify("tts: " .. detail, vim.log.levels.WARN)
            end
            if current_job == job_id then
                current_job = nil
            end
        end,
    })
    if text then
        vim.fn.chansend(current_job, text)
        vim.fn.chanclose(current_job, "stdin")
    end
end

-- 定义插件功能
local function text_to_speech()
    -- 获取当前选中的文本
    local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
    local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    -- 处理选中文本
    if #lines == 0 then
        print("No text selected!")
        return
    end

    -- 将多行文本合并为一行
    local text = table.concat(lines, " ")
    -- text = string.gsub(text, "%s+", " ") -- 去除多余的空格
    -- text = string.gsub(text, "_", " ")
    -- text = string.gsub(text, "//", " ")
    -- text = string.gsub(text, "*", " ")
    -- text = string.gsub(text, "`", " ")
    -- text = string.gsub(text, "#", " ")
    -- text = string.gsub(text, "%[", " ")
    -- text = string.gsub(text, "%]", " ")
    -- text = string.gsub(text, "<", " ")
    -- text = string.gsub(text, ">", " ")
    -- text = string.gsub(text, "/", " ")
    -- text = string.gsub(text, "\"", " ")

    start_job({ config.python, rapid_script, config.backend }, text)
    print("tts: 正在生成音频...")
end

-- 停止当前音频播放
local function stop_audio()
    if current_job then
        stop_job()
        print("tts: 已停止")
    else
        print("tts: 没有正在播放的音频")
    end
end

-- 重新播放最近的音频
local function replay_audio()
    if vim.fn.filereadable(last_wav) == 1 then
        start_job({ config.python, rapid_script, "replay" })
        print("tts: 正在播放...")
    else
        print("tts: 没有最近的音频文件")
    end
end

vim.api.nvim_set_keymap("v", "<leader>tts", ":lua require('tts').text_to_speech()<CR>", { noremap = true, silent = true, desc = "Text To Speech" })
vim.api.nvim_set_keymap("n", "<leader>tts", ":lua require('tts').stop_audio()<CR>", { noremap = true, silent = true , desc = "TTS Stop" })
vim.api.nvim_set_keymap("n", "<leader>ttr", ":lua require('tts').replay_audio()<CR>", { noremap = true, silent = true, desc = "TTS Replay" })

-- 导出模块
return {
    setup = setup,
    text_to_speech = text_to_speech,
    stop_audio = stop_audio,
    replay_audio = replay_audio,
}
