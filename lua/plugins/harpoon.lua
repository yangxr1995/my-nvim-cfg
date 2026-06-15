return {
    {
        "ThePrimeagen/harpoon",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        event = "VeryLazy",
        keys = {
            { "<leader>ha", function() require("harpoon.mark").add_file() end,                 desc = "标记文件到 Harpoon" },
            { "<leader>hn", function() require("harpoon.ui").nav_next() end,                    desc = "跳转到下一个 Harpoon 文件" },
            { "<leader>hp", function() require("harpoon.ui").nav_prev() end,                    desc = "跳转到上一个 Harpoon 文件" },
            { "<leader>1",  function() require("harpoon.ui").nav_file(1) end,                   desc = "跳转到 Harpoon 文件 1" },
            { "<leader>2",  function() require("harpoon.ui").nav_file(2) end,                   desc = "跳转到 Harpoon 文件 2" },
            { "<leader>3",  function() require("harpoon.ui").nav_file(3) end,                   desc = "跳转到 Harpoon 文件 3" },
            { "<leader>4",  function() require("harpoon.ui").nav_file(4) end,                   desc = "跳转到 Harpoon 文件 4" },
            { "<leader>5",  function() require("harpoon.ui").nav_file(5) end,                   desc = "跳转到 Harpoon 文件 5" },
            { "<leader>hs", function() require("telescope").extensions.harpoon.marks() end,     desc = "Telescope 查看 Harpoon 文件列表" },
        },
        config = function()
            require("harpoon").setup({
                global_settings = {
                    -- 按 git 分支存储 marks，不同分支独立记录
                    mark_branch = true,
                },
            })

            local status_ok, telescope = pcall(require, "telescope")
            if status_ok then
                pcall(telescope.load_extension, "harpoon")
            end
        end,
    },
}
