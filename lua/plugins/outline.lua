return  {
    {
        "hedyhli/outline.nvim",
        lazy = true,
        cmd = { "Outline", "OutlineOpen" },
        keys = { -- Example mapping to toggle outline
            { "<F3>", function()
                -- md-render's render view is a plain buffer with no outline
                -- structure; toggle back to source first so the outline
                -- parses the actual markdown (sessions are kept, <leader>mr
                -- re-renders afterwards).
                local state = vim.w.md_render_state
                if state and state.mode == "render" and state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
                    require("md-render").preview.toggle()
                end
                vim.cmd("Outline")
            end, desc = "Toggle outline" },
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
                        local ft = vim.bo[buf].filetype
                        if ft == 'outline' then
                            vim.api.nvim_win_close(win, true)
                        end
                    end
                end,
            })
        end
    },
}

