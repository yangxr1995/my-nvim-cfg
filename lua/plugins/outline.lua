return  {
    {
        "hedyhli/outline.nvim",
        lazy = true,
        cmd = { "Outline", "OutlineOpen" },
        keys = { -- Example mapping to toggle outline
            { "<F3>", mode = "n", "<cmd>Outline<CR>", desc = "Toggle outline" },
        },
        opts = {
        },
        config = function ()
            local status_ok, outline = pcall(require, "outline")
            if not status_ok then
                return
            end

            outline.setup()

            vim.api.nvim_create_autocmd("VimLeave", {
                callback = function()
                    local wins = vim.api.nvim_list_wins()
                    for _, win in ipairs(wins) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
                        if ft == 'outline' then
                            vim.api.nvim_win_close(win, true)
                        end
                    end
                end,
            })
        end
    },
}

