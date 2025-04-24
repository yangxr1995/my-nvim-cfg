return {
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        lazy = false,
        version = false, -- set this if you want to always pull the latest change
        opts = {
            provider = "openai",
            auto_suggestions_provider = "openai", -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
            openai = {
                -- endpoint = "https://open.bigmodel.cn/api/paas/v4/",
                -- model = "glm-4-flash",

                -- endpoint = "https://api.deepseek.com/v1",
                -- model = "deepseek-chat",

                endpoint="http://api.siliconflow.cn/v1",
                model = "Pro/deepseek-ai/DeepSeek-V3",
                -- model = "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B",

                -- endpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1",
                -- model = "qwen-plus",

                timeout = 30000, -- Timeout in milliseconds
                temperature = 0,
                max_tokens = 4096,
                stream = true,
                -- ["local"] = false,
            },
            hints = { enabled = false },
        },
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
        dependencies = {
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua", -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
            {
                -- Make sure to set this up properly if you have lazy=true
                'MeanderingProgrammer/render-markdown.nvim',
                opts = {
                    file_types = { "markdown", "Avante" },
                },
                ft = { "markdown", "Avante" },
            },
        },
    }
}
