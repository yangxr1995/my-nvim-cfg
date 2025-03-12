local function local_llm_streaming_handler(chunk, line, assistant_output, bufnr, winid, F)
    if not chunk then
        return assistant_output
    end
    local tail = chunk:sub(-1, -1)
    if tail:sub(1, 1) ~= "}" then
        line = line .. chunk
    else
        line = line .. chunk
        local status, data = pcall(vim.fn.json_decode, line)
        if not status or not data.message.content then
            return assistant_output
        end
        assistant_output = assistant_output .. data.message.content
        F.WriteContent(bufnr, winid, data.message.content)
        line = ""
    end
    return assistant_output
end

local function local_llm_parse_handler(chunk)
    local assistant_output = chunk.message.content
    return assistant_output
end


return {
    {
        "Kurama622/llm.nvim",
        commit = "f2bf6540bd32bf5a1b465dbd433238a32d817e96",
        dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
        cmd = { "LLMSesionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
        keys = {
            { "<leader>lltc", mode = "x", "<cmd>LLMSelectedTextHandler 翻译为中文<cr>", desc = "英译汉" },
            { "<leader>llte", mode = "x", "<cmd>LLMSelectedTextHandler 翻译为英文<cr>", desc = "汉译英" },
            { "<leader>llr", mode = "n", "<cmd>LLMAppHandler Translate<cr>", desc = "llm翻译" },
        },
        config = function()
            local tools = require("llm.common.tools")
            require("llm").setup({

                -- [[ollama]]
                api_type = "ollama",
                url = "http://192.168.33.1:11434/api/chat", -- your url
                -- model = "deepseek-r1:1.5b",
                model = "qwen2.5:1.5b",
                -- model = "modelscope.cn/Qwen/Qwen2.5-3B-Instruct-GGUF:latest",

                temperature = 0.3,
                top_p = 0.7,

                prompt = "你是中英文翻译助手.",

                prefix = {
                    user = { text = "😃 ", hl = "Title" }, ------------ 
                    assistant = { text = "  ", hl = "Added" },
                },

                save_session = true,
                max_history = 15,
                max_history_name_length = 20,

                -- stylua: ignore
                -- popup window options
                popwin_opts = {
                    relative = "cursor", enter = true,
                    focusable = true, zindex = 50,
                    position = { row = -7, col = 15, },
                    size = { height = 15, width = "50%", },
                    border = { style = "single",
                    text = { top = " Explain ", top_align = "center" },
                },
                win_options = {
                    winblend = 0,
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                },
            },

            -- stylua: ignore
            keys = {
                -- The keyboard mapping for the input window.
                ["Input:Submit"]      = { mode = "n", key = "<cr>" },
                ["Input:Cancel"]      = { mode = {"n", "i"}, key = "<C-c>" },
                ["Input:Resend"]      = { mode = {"n", "i"}, key = "<C-r>" },

                -- only works when "save_session = true"
                ["Input:HistoryPrev"] = { mode = {"n", "i"}, key = "<A-k>" },
                ["Input:HistoryNext"] = { mode = {"n", "i"}, key = "<A-j>" },

                -- The keyboard mapping for the output window in "split" style.
                ["Output:Ask"]        = { mode = "n", key = "i" },
                ["Output:Cancel"]     = { mode = "n", key = "<C-c>" },
                ["Output:Resend"]     = { mode = "n", key = "<C-r>" },

                -- The keyboard mapping for the output and input windows in "float" style.
                ["Session:Toggle"]    = { mode = "n", key = "<leader>ac" },
                ["Session:Close"]     = { mode = "n", key = {"<esc>", "Q"} },
            },

            streaming_handler = local_llm_streaming_handler,
            app_handler = {
                Translate = {
                    prompt = [[以下内容若为中文则翻译为英文，若为英文则翻译为中文]],
                    handler = tools.qa_handler,
                    opts = {
                        parse_handler = local_llm_parse_handler,
                        exit_on_move = true,
                        enter_flexible_window = false,
                    },

                },
            },

        })
        end,
    },
    {
        'luozhiya/fittencode.nvim',
        lazy= true,
        event = "VeryLazy",
        config = function()
            require('fittencode').setup({
                completion_mode ='source',
            })
            vim.opt.updatetime = 200
        end,

    },
}
