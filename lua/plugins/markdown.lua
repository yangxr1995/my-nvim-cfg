-- Render width follows the current window's usable text width
-- (plugin default caps at 80 columns; explicit max_width opts bypass it).
local function render_width()
    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    local textoff = wininfo and wininfo.textoff or 0
    return math.max(1, vim.api.nvim_win_get_width(0) - textoff)
end

-- Seed expand_state so tables render with wrapped cells instead of
-- truncated ones. Expand ids are the 1-based source line of each table's
-- first row (a "|..." line whose next line is the |---| separator).
local function table_expand_state(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local state = {}
    for i = 1, #lines - 1 do
        if lines[i]:match("^%s*|") and lines[i + 1]:match("^%s*|?%s*[%-:|%s]+$") and lines[i + 1]:find("%-%-") then
            state[i] = true
        end
    end
    return state
end

-- Session.new resets opts.expand_state to its own interactive table,
-- so tables-expanded-by-default has to be injected after creation.
local function seed_expanded_tables(preview, bufnr)
    local seed = table_expand_state(bufnr)
    if next(seed) == nil then return end
    local pools = { preview._toggle_sessions, preview._sessions }
    for _, pool in ipairs(pools) do
        for _, session in pairs(pool or {}) do
            if session.source_bufnr == bufnr then
                for id in pairs(seed) do
                    session.expand_state[id] = true
                end
                session:rebuild()
            end
        end
    end
end

return {
    {
        "delphinus/md-render.nvim",
        version = "*",
        dependencies = {
            { "nvim-tree/nvim-web-devicons", version = "*" },
            { "delphinus/budoux.lua", version = "*" },
        },
        ft = { "markdown" },
        keys = {
            {
                "<leader>mp",
                function()
                    local preview = require("md-render").preview
                    local bufnr = vim.api.nvim_get_current_buf()
                    preview.show({ max_width = render_width() })
                    seed_expanded_tables(preview, bufnr)
                end,
                desc = "Markdown preview (float toggle)",
            },
        },
        config = function()
            local preview = require("md-render").preview

            -- Rendered view in normal mode, source in insert mode.
            -- Deferred: creating the render buffer inside the FileType autocmd chain
            -- re-enters ftplugin/treesitter processing and breaks parser startup.
            local function auto_on()
                vim.schedule(function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    preview.auto_on({ max_width = render_width() })
                    seed_expanded_tables(preview, bufnr)
                end)
            end
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = auto_on,
            })
            -- lazy.nvim re-triggers FileType after loading via `ft`, so the
            -- autocmd above also covers the buffer that triggered the load.

            -- Re-render on window resize: explicit max_width disables the
            -- plugin's built-in WinResized adaptation (and auto_on opts are
            -- ignored by session reuse), so update the session in place.
            vim.api.nvim_create_autocmd("VimResized", {
                callback = function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local ft = vim.bo[bufnr].filetype
                    if ft ~= "markdown" and ft ~= "md-render" then return end
                    local src = (vim.w.md_render_state or {}).source_buf or bufnr
                    local session = preview._toggle_sessions[src]
                    if not session then return end
                    session.opts.max_width = render_width()
                    pcall(function() session:rebuild() end)
                end,
            })
        end,
    },
    {
        "HakonHarnes/img-clip.nvim",
        -- event = "VeryLazy",
        ft = { "markdown" },
        opts = {
            -- add options here
            -- or leave it empty to use the default settings
            default = {
                extension = "jpg",
            }
        },
        keys = {
            -- suggested keymap
            { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
        },
    },
}
