-- tts.lua

-- 默认配置
local config = {
    rate = "+0%", -- 默认播放速度（不调整）
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

    -- 生成临时 MP3 文件路径
    local temp_file = os.tmpname() .. ".mp3"

    -- 使用 edge-tts 将文本转换为 MP3，并调整速度
    local cmd = string.format(
        'edge-tts --text "%s" --write-media %s --rate=%s',
        text,
        temp_file,
        config.rate
    )
    local result = vim.fn.system(cmd)

    -- 检查是否成功生成 MP3 文件
    if vim.fn.filereadable(temp_file) == 0 then
        print("Failed to generate MP3 file!")
        return
    end

    -- 使用 mocp 播放 MP3 文件
    local play_cmd = string.format("mocp -l %s &", temp_file)
    vim.fn.system(play_cmd)

    -- 提示用户
    print("Playing selected text as audio...")
end

-- 绑定快捷键
vim.api.nvim_set_keymap("v", "<leader>tts", ":lua require('tts').text_to_speech()<CR>", { noremap = true, silent = true })

-- 导出模块
return {
    setup = setup,
    text_to_speech = text_to_speech,
}
