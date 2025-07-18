-- tts.lua

-- 默认配置
local config = {
    rate = "+20%", -- 默认播放速度（不调整）
}


-- 设置配置
local function setup(opts)
    config = vim.tbl_extend("force", config, opts or {})
end

-- 检查并启动 mocp 服务器
local function ensure_mocp_server()
    -- 检查 mocp 服务器是否正在运行
    local check_cmd = "mocp -i > /dev/null 2>&1"
    local is_running = vim.fn.system(check_cmd) == 0

    -- 如果未运行，则启动 mocp 服务器
    if not is_running then
        print("Starting mocp server...")
        vim.fn.system("mocp -S &")
        vim.fn.system("sleep 1")
    end
end

-- 定义插件功能
local function text_to_speech()
    -- 确保 mocp 服务器已启动
    ensure_mocp_server()

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

    -- print("Selected text: ", text)

    -- 生成固定路径的 MP3 文件
    local cache_dir = vim.fn.stdpath("cache") .. "/tts"
    vim.fn.mkdir(cache_dir, "p")
    local audio_file = cache_dir .. "/last_audio.mp3"

    local voice = "zh-TW-HsiaoChenNeural"

    -- print("audio_file : ", audio_file);
    -- 使用 edge-tts 将文本转换为 MP3，并调整速度
    local cmd = string.format(
        'edge-tts --text "%s" --write-media %s --rate=%s --voice=%s',
        text,
        audio_file,
        config.rate,
        voice
    )

    -- 异步执行 edge-tts 命令
    vim.fn.jobstart(cmd, {
        on_exit = function(_, exit_code)
            if exit_code == 0 then
                -- 检查是否成功生成 MP3 文件
                if vim.fn.filereadable(audio_file) == 1 then
                    -- 使用 mocp 播放 MP3 文件
                    local play_cmd = string.format("mocp -l %s &", audio_file)
                    vim.fn.jobstart(play_cmd, {
                        on_exit = function(_, play_exit_code)
                            if play_exit_code == 0 then
                                print("Playing selected text as audio...")
                            else
                                print("Failed to play MP3 file!")
                            end
                        end
                    })
                else
                    print("Failed to generate MP3 file!")
                end
            else
                print("Failed to convert text to speech!")
            end
        end
    })
end

-- 停止当前音频播放
local function stop_audio()
    vim.fn.system("mocp -x")
    print("Audio playback stopped.")
end

-- 重新播放最近的音频
local function replay_audio()
    -- 生成固定路径的 MP3 文件
    local cache_dir = vim.fn.stdpath("cache") .. "/tts"
    vim.fn.mkdir(cache_dir, "p")
    local audio_file = cache_dir .. "/last_audio.mp3"

    print("audio_file : ", audio_file);
    if audio_file and vim.fn.filereadable(audio_file) == 1 then
        ensure_mocp_server()
        local play_cmd = string.format("mocp -l %s &", audio_file)
        vim.fn.system(play_cmd)
        print("Replaying last audio...")
    else
        print("No recent audio file found!")
    end
end

vim.api.nvim_set_keymap("v", "<leader>tts", ":lua require('tts').text_to_speech()<CR>", { noremap = true, silent = true, desc = "Text To Speed" })
vim.api.nvim_set_keymap("n", "<leader>tts", ":lua require('tts').stop_audio()<CR>", { noremap = true, silent = true , desc = "TTS Stop" })
vim.api.nvim_set_keymap("n", "<leader>ttr", ":lua require('tts').replay_audio()<CR>", { noremap = true, silent = true, desc = "TTS Replay" })

-- 导出模块
return {
    setup = setup,
    text_to_speech = text_to_speech,
    stop_audio = stop_audio,
    replay_audio = replay_audio,
}

