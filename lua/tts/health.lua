-- checkhealth entry for the tts module (`:checkhealth tts`)

local voices_dir = vim.fn.stdpath("data") .. "/tts/piper_voices"
local models = {
    "zh_CN-huayan-medium",
    "en_US-lessac-medium",
}

local M = {}

function M.check()
    vim.health.start("tts")

    if vim.fn.executable("python3") == 1 then
        vim.health.ok("python3 found")
    else
        vim.health.error("python3 not found", { "install python3 first" })
    end

    if vim.fn.executable("ffplay") == 1 then
        vim.health.ok("ffplay found (audio playback)")
    else
        vim.health.error("ffplay not found", { "sudo apt install ffmpeg" })
    end

    vim.fn.system({ "python3", "-c", "import piper" })
    if vim.v.shell_error == 0 then
        vim.health.ok("piper-tts (python library) found")
    else
        vim.health.error("piper-tts (python library) not installed", {
            "python3 -m pip install --break-system-packages piper-tts",
        })
    end

    for _, name in ipairs(models) do
        local model = voices_dir .. "/" .. name .. ".onnx"
        if vim.uv.fs_stat(model) then
            vim.health.ok("voice model: " .. name)
        else
            vim.health.error("voice model missing: " .. model)
        end
    end
end

return M
