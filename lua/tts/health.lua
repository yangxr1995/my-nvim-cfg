-- checkhealth entry for the tts module (`:checkhealth tts`)

local rapidtts_python = "/root/test/tts/.venv/bin/python"

local M = {}

function M.check()
    vim.health.start("tts")

    if vim.fn.executable("ffplay") == 1 then
        vim.health.ok("ffplay found (audio playback)")
    else
        vim.health.error("ffplay not found", { "sudo apt install ffmpeg" })
    end

    -- rapidtts backends (kokoro / moss, default)
    if vim.uv.fs_stat(rapidtts_python) then
        vim.health.ok("rapidtts python: " .. rapidtts_python)
        vim.fn.system({ rapidtts_python, "-c", "import rapidtts" })
        if vim.v.shell_error == 0 then
            vim.health.ok("rapidtts (python library) found")
        else
            vim.health.error("rapidtts (python library) not installed", {
                "run inside /root/test/tts:",
                '.venv/bin/pip install "rapidtts[kokoro]" "rapidtts[moss_nano]"',
            })
        end
    else
        vim.health.error("rapidtts python not found: " .. rapidtts_python, {
            "create the venv inside /root/test/tts and install rapidtts",
        })
    end
end

return M
