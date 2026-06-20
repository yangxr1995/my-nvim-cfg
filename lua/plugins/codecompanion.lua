local function deepseek_adapter(name, model, can_reason)
    return function()
        return require("codecompanion.adapters").extend("deepseek", {
            name = name,
            url = "https://api.deepseek.com/chat/completions",
            env = {
                api_key = function()
                    return os.getenv("DEEPSEEK_API_KEY")
                end,
            },
            schema = {
                model = {
                    default = model,
                    choices = {
                        [model] = { opts = { can_reason = false }},
                    }
                },
                think = {
                    default = false,
                }
            },
        })
    end
end

--- NOTE: '<' / '>' 标记只在退出 visual mode 后才更新，
--- visual mode 进行中它们还是上一次选区的位置。
--- 改用 getpos("v") / getpos(".") 拿到当前选区实时坐标。
---@return string|nil
local function get_visual_selection()
    local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
    if #region == 0 then return nil end
    local text = table.concat(region, '\n')
    if text == '' then return nil end
    return text
end

local function translate_selection()
    local text = get_visual_selection()
    if not text or text == '' then return end
    local api_key = os.getenv("DEEPSEEK_API_KEY")
    if not api_key or api_key == '' then
        print("DEEPSEEK_API_KEY 未设置")
        return
    end

    local prompt = "将以下文本翻译为中文，直接给出翻译结果不要解释：\n\n" .. text
    local payload = vim.json.encode({
        model = "deepseek-v4-flash",
        messages = { { role = "user", content = prompt } },
        stream = false,
    })

    local result = vim.fn.system({
        "curl", "-s",
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. api_key,
        "-d", payload,
        "https://api.deepseek.com/chat/completions",
    })
    if vim.v.shell_error ~= 0 then
        print("翻译请求失败: " .. result)
        return
    end
    local ok, resp = pcall(vim.json.decode, result)
    if not ok or not resp.choices or not resp.choices[1] then
        print("解析响应失败")
        return
    end
    local translation = resp.choices[1].message.content
    if not translation or translation == '' then
        print("未获取到翻译结果")
        return
    end

    local lines = vim.split(translation, '\n', { plain = true })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown"

    local width = math.min(80, vim.o.columns - 8)
    local height = math.min(#lines + 2, vim.o.lines - 8)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        border = "rounded",
        style = "minimal",
        title = " 翻译结果 ",
        title_pos = "center",
    })
    vim.wo[win].wrap = true
    vim.keymap.set("n", "q", function() pcall(vim.api.nvim_win_close, win, true) end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<esc>", function() pcall(vim.api.nvim_win_close, win, true) end, { buffer = buf, nowait = true })
end

return {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "j-hui/fidget.nvim",
    },
    keys = {
        { "<leader>c", group = "CodeCompanion" },
        { "<leader>ca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "操作面板" },
        { "<leader>ct", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "切换聊天" },
        { "<leader>ci", "<cmd>CodeCompanion<cr>", mode = "n", desc = "内联对话" },
        { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "添加到聊天" },
        { "<leader>cT", translate_selection, mode = "v", desc = "翻译选中文本" },
    },
    config = function()
        local ret, CCFidgeHooks = pcall(require, "CCFidgeHooks")
        if not ret then
            print("cant find CCFidgeHooks")
        end
        CCFidgeHooks.init()

        require("codecompanion").setup({
            opts = {
                language = "Chinese",
                send_code = true,
            },
            adapters = {
                http = {
                    deepseek_v4f = deepseek_adapter("deepseek", "deepseek-v4-flash", false),
                },
            },
            strategies = {
                chat = { adapter = "deepseek_v4f" },
                inline = { adapter = "deepseek_v4f" },
            },
            display = {
                chat = {
                    window = {
                        layout = "float",
                        width = 0.5,
                        height = 0.75,
                        border = "single",
                    },
                    show_token_count = true,
                    show_reasoning = true,
                    start_in_insert_mode = false,
                },
                inline = {
                    layout = "vertical",
                },
                diff = {
                    enabled = true,
                },
            },
            interactions = {
                inline = {
                    keymaps = {
                        accept_change = {
                            modes = { n = "gda" },
                            description = "接受修改",
                        },
                        reject_change = {
                            modes = { n = "gdr" },
                            description = "拒绝修改",
                        },
                    },
                },
            },
        })

        vim.cmd([[cab cc CodeCompanion]])
        vim.cmd([[cab ccchat CodeCompanionChat]])
    end,
}

