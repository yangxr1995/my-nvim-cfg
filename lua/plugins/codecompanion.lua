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

return {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "j-hui/fidget.nvim",
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
                    deepseek_v4f = deepseek_adapter("deepseek", "deepseek-v4-flash", false),
                },
            },

            strategies = {
                chat = {adapter = "deepseek_v4f"},
                inline = {adapter = "deepseek_v4f"}
            },
        })
    end,
}

