return {
    {
        "christoomey/vim-tmux-navigator",
        lazy = false,
        keys = {
            { "<C-h>", mode = "n", "<cmd>TmuxNavigateLeft<CR>", desc = "window left" },
            { "<C-l>", mode = "n", "<cmd>TmuxNavigateRight<CR>", desc = "window right" },
            { "<C-j>", mode = "n", "<cmd>TmuxNavigateDown<CR>", desc = "window down" },
            { "<C-k>", mode = "n", "<cmd>TmuxNavigateUp<CR>", desc = "window up" },
        },
    }
}
