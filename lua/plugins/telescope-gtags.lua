return {
    {
        "yangxr1995/telescope-gtags",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        keys = {
            { "<leader>gd",  mode = "n", function() require("telescope-gtags").showDefinition() end,          desc = "gtags 查找定义" },
            { "<leader>gr",  mode = "n", function() require("telescope-gtags").showReference() end,           desc = "gtags 查找引用" },
            { "<leader>gir", mode = "n", function() require("telescope-gtags").showReferenceFromInput() end,  desc = "gtags 查找引用（输入）" },
            { "<leader>gid", mode = "n", function() require("telescope-gtags").showDefinitionFromInput() end, desc = "gtags 查找定义（输入）" },
        },
        lazy = true,
        config = function()
            local status_ok, gtags = pcall(require, "telescope-gtags")
            if not status_ok then
                return
            end
            gtags.setAutoIncUpdate(true)
            -- Initialize stack_view with default options
            gtags.setup({ stack_view = { tree_hl = true, size = "medium" } })
        end,
    },
}
