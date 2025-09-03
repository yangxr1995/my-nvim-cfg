
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

return {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
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

                    siliconflow_deepseek = function ()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            name = "siliconflow_deepseek",
                            env = {
                                url = "http://api.siliconflow.cn",
                                api_key = function ()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                                chat_url = "/v1/chat/completions",
                            },
                            schema = {
                                model = {
                                    default = "Pro/deepseek-ai/DeepSeek-V3",
                                },
                            },
                        })
                    end,

                    siliconflow_deepseek_r = function ()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_deepseek_r",
                            url = "http://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = function ()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "Pro/deepseek-ai/DeepSeek-R1",
                                    choices = {
                                        ["Pro/deepseek-ai/DeepSeek-R1"] = { opts = { can_reason = true }},
                                    }
                                },
                            },
                        })
                    end,

                    siliconflow_qwen3 = function ()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_qwen3",
                            url = "http://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = function ()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "Qwen/Qwen3-235B-A22B",
                                    choices = {
                                        ["Qwen/Qwen3-235B-A22B"] = { opts = { can_reason = true }},
                                    }
                                },
                            },
                        })
                    end,

                    siliconflow_qwen3_coder = function ()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_qwen3_coder",
                            url = "http://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = function ()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "Qwen/Qwen3-Coder-480B-A35B-Instruct",
                                    choices = {
                                        ["Qwen/Qwen3-Coder-480B-A35B-Instruct"] = { opts = { can_reason = false }},
                                    }
                                },
                            },
                        })
                    end,

                    siliconflow_qwen3_8b = function ()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_qwen3_8b",
                            url = "http://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = function ()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "Qwen/Qwen3-8B",
                                    choices = {
                                        ["Qwen/Qwen3-8B"] = { opts = { can_reason = false }},
                                    }
                                },
                            },
                        })
                    end,

                    siliconflow_glm_z1_9b = function ()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "siliconflow_glm_z1_9b",
                            url = "http://api.siliconflow.cn/v1/chat/completions",
                            env = {
                                api_key = function ()
                                    return os.getenv("DEEPSEEK_API_KEY_S")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "THUDM/GLM-Z1-9B-0414",
                                    choices = {
                                        ["THUDM/GLM-Z1-9B-0414"] = { opts = { can_reason = false }},
                                    }
                                },
                            },
                        })
                    end,



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
                chat = {adapter = "siliconflow_qwen3"},
                inline = {adapter = "siliconflow_qwen3_coder"}

                -- chat = {adapter = "siliconflow_deepseek"},
                -- inline = {adapter = "siliconflow_deepseek"}
            },

            prompt_library = {
                ["翻译为中文"] = {
                    strategy = "chat",
                    description = "将所选内容翻译为中文",
                    opts = {
                        models = { "v" },
                        user_prompt = false,
                        is_slash_cmd = false,
                        auto_submit = true,
                        short_name = "translate_to_zh",
                        stop_context_insertion = true,
                        adapter = {
                            name = "siliconflow_qwen3_8b",
                            model = "Qwen/Qwen3-8B"

                            -- name = "siliconflow_glm_z1_9b",
                            -- model = "THUDM/GLM-Z1-9B-0414"
                        },

                        -- adapter = {
                        --     name = "ollama",
                        --     model = "qwen3"
                        -- },
                    },
                    prompts = {
                        {
                            role = "system",
                            content = "你是英译汉专家",
                            opts = {
                                visible = false,
                            },
                        },
                        {
                            role = "user",
                            content = function (context)
                                local input = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                                return string_filter(input, "请将接下来的内容翻译为中文，不要做翻译外的任何工作:'%s'")
                            end,
                        }
                    },
                },

                ["翻译为英文"] = {
                    strategy = "chat",
                    description = "将所选内容翻译为英文",
                    opts = {
                        models = { "v" },
                        user_prompt = false,
                        is_slash_cmd = false,
                        auto_submit = true,
                        short_name = "translate_to_en",
                        stop_context_insertion = true,
                        adapter = {
                            name = "siliconflow_qwen3_8b",
                            model = "Qwen/Qwen3-8B",

                            -- name = "siliconflow_glm_z1_9b",
                            -- model = "THUDM/GLM-Z1-9B-0414"
                        },

                        -- adapter = {
                        --     name = "ollama",
                        --     model = "qwen3"
                        -- },
                    },
                    prompts = {
                        {
                            role = "system",
                            content = "你是汉译英专家",
                            opts = {
                                visible = false,
                            },
                        },
                        {
                            role = "user",
                            content = function (context)
                                local input = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                                return string_filter(input, "请将接下来的内容翻译为英文，不要做翻译外的任何工作:'%s'")
                            end,
                            }
                        },
                    },
                },
            })
        end,

    }

