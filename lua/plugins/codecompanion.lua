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
    local prompt = "将以下文本翻译为中文，直接给出翻译结果不要解释：\n\n" .. text
    require("codecompanion").chat({
        user_prompt = prompt,
        auto_submit = true,
    })
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

