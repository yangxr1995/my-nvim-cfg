-- tts.lua: local Piper TTS, synthesis/playback handled by tools/tts_speak.py

-- 默认配置
local config = {
    lang = "zh", -- "zh" or "en", maps to models in tools/tts_speak.py
}

local script = vim.fn.stdpath("config") .. "/tools/tts_speak.py"
local last_wav = vim.fn.stdpath("cache") .. "/tts/last_audio.wav"
local current_job = nil

-- 设置配置
local function setup(opts)
    config = vim.tbl_extend("force", config, opts or {})
end

local function stop_job()
    if current_job then
        vim.fn.jobstop(current_job)
        current_job = nil
    end
end

local function start_job(args, text)
    stop_job()
    local stderr_lines = {}
    current_job = vim.fn.jobstart(vim.list_extend({ "python3", script }, args), {
        on_stderr = function(_, data)
            for _, line in ipairs(data or {}) do
                if line ~= "" and #stderr_lines < 5 then
                    table.insert(stderr_lines, line)
                end
            end
        end,
        on_exit = function(job_id, exit_code)
            if current_job == job_id then
                current_job = nil
            end
            if exit_code ~= 0 then
                -- surface script diagnostics (e.g. missing piper/model install hints)
                local detail = #stderr_lines > 0 and table.concat(stderr_lines, "\n")
                    or ("exited with code " .. exit_code)
                vim.notify("tts: " .. detail, vim.log.levels.WARN)
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
    text = string.gsub(text, "%s+", " ") -- 去除多余的空格
    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "//", " ")
    text = string.gsub(text, "*", " ")
    text = string.gsub(text, "`", " ")
    text = string.gsub(text, "#", " ")
    text = string.gsub(text, "%[", " ")
    text = string.gsub(text, "%]", " ")
    text = string.gsub(text, "<", " ")
    text = string.gsub(text, ">", " ")
    text = string.gsub(text, "/", " ")
    text = string.gsub(text, "\"", " ")

    start_job({ config.lang }, text)
    print("Playing selected text as audio...")
end

-- 停止当前音频播放
local function stop_audio()
    if current_job then
        stop_job()
        print("Audio playback stopped.")
    else
        print("No audio playing.")
    end
end

-- 重新播放最近的音频
local function replay_audio()
    if vim.fn.filereadable(last_wav) == 1 then
        start_job({ "replay" })
        print("Replaying last audio...")
    else
        print("No recent audio file found!")
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
