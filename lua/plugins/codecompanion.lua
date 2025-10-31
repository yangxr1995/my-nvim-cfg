local function string_filter(input, prefix)
    input = string.gsub(input, "#", " ")
    input = string.gsub(input, "@", " ")
    input = string.gsub(input, "/", " ")
    input = string.gsub(input, "|", " ")
    input = string.gsub(input, "&", " ")
    input = string.gsub(input, "<", " ")
    input = string.gsub(input, ">", " ")
    input = string.gsub(input, "%[", " ")
    input = string.gsub(input, "%]", " ")
    input = string.gsub(input, "'", " ")
    input = string.gsub(input, "`", " ")
    return string.format(
        prefix,
        input)
end

-- minimax
local function minimax_adapter(name, model, can_reason)
    return function()
        return require("codecompanion.adapters").extend("deepseek", {
            name = name,
            url = "https://api.minimaxi.com/v1/chat/completions",
            env = {
                api_key = function()
                    return os.getenv("MINIMAX_API_KEY")
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

-- 硅基流动适配器工厂函数
local function siliconflow_adapter(name, model, can_reason)
    return function()
        return require("codecompanion.adapters").extend("deepseek", {
            name = name,
            url = "http://api.siliconflow.cn/v1/chat/completions",
            env = {
                api_key = function()
                    return os.getenv("DEEPSEEK_API_KEY_S")
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

local function translate_adapter(language, short_name)
    return {
        strategy = "chat",
        description = "将所选内容翻译为" .. language,
        opts = {
            models = { "v" },
            user_prompt = false,
            is_slash_cmd = false,
            auto_submit = true,
            short_name = "translate_to_" .. short_name,
            stop_context_insertion = true,
            adapter = {
                -- name = "siliconflow_qwen3_8b",
                -- model = "Qwen/Qwen3-8B"

                name = "siliconflow_glm_32b",
                model = "THUDM/GLM-4-32B-0414"
            },
        },
        prompts = {
            {
                role = "system",
                content = "你是翻译专家，尤其擅长将各类语言翻译为" .. language,
                opts = {
                    visible = false,
                },
            },
            {
                role = "user",
                content = function (context)
                    local input = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                    return string_filter(input, "请将接下来的内容翻译为" .. language .. "，不要做翻译外的任何工作，不需要显示原文，只显示翻译结果:'%s'")
                end,
            }
        },
    }
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
        { "<leader>lltc", mode = "x",
        function()
            require("codecompanion").prompt("translate_to_zh")
        end,
        desc = "英译汉" },
        { "<leader>llte", mode = "x",
        function()
            require("codecompanion").prompt("translate_to_en")
        end,
        desc = "英译汉" },
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
            },
            adapters = {
                http = {

                    deepseek = function ()
                        return require("codecompanion.adapters").extend("deepseek", {
                            env = {
                                api_key = function()
                                    return os.getenv("DEEPSEEK_API_KEY")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-chat",
                                },
                            },
                        })
                    end,

                    minimax_m2 = minimax_adapter("minimax_m2", "MiniMax-M2", false),
                    siliconflow_deepseek = siliconflow_adapter("siliconflow_deepseek", "Pro/deepseek-ai/DeepSeek-V3.1", true),
                    siliconflow_deepseek_r = siliconflow_adapter("siliconflow_deepseek_r", "Pro/deepseek-ai/DeepSeek-R1", true),
                    siliconflow_qwen3 = siliconflow_adapter("siliconflow_qwen3", "Qwen/Qwen3-235B-A22B", false),
                    siliconflow_qwen3_coder = siliconflow_adapter("siliconflow_qwen3_coder", "Qwen/Qwen3-Coder-480B-A35B-Instruct", false),
                    siliconflow_qwen3_8b = siliconflow_adapter("siliconflow_qwen3_8b", "Qwen/Qwen3-8B", false),
                    siliconflow_glm_z1_9b = siliconflow_adapter("siliconflow_glm_z1_9b", "THUDM/GLM-Z1-9B-0414", false),
                    siliconflow_glm_32b = siliconflow_adapter("siliconflow_glm_32b", "THUDM/GLM-4-32B-0414", false),


                    ollama = function()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            name = "ollama", -- Give this adapter a different name to differentiate it from the default ollama adapter
                            url = "${url}/v1/chat/completions",
                            env = {
                                url = "http://192.168.3.1:11434",
                                chat_url = "/api/chat", -- optional: default value, override if different
                                models_endpoint = "/api/tags", -- optional: attaches to the end of the URL to form the endpoint to retrieve models
                            },
                            schema = {
                                model = {
                                    default = "qwen3",
                                },
                            },
                        })
                    end,

                },

            },

            strategies = {
                -- chat = {adapter = "siliconflow_deepseek"},
                chat = {adapter = "minimax_m2"},
                inline = {adapter = "siliconflow_qwen3_coder"}
            },

            prompt_library = {
                ["翻译为中文"] = translate_adapter("中文", "zh"),
                ["翻译为英文"] = translate_adapter("英文", "en"),
            },
        })
    end,

    }

