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
            {
                "<leader>mr",
                function()
                    local preview = require("md-render").preview
                    local bufnr = vim.api.nvim_get_current_buf()
                    preview.toggle({ max_width = render_width() })
                    -- Seed only when the window switched to the render view;
                    -- toggling back leaves the (reused) session untouched.
                    local state = vim.w.md_render_state
                    if state and state.mode == "render" and state.source_buf == bufnr then
                        seed_expanded_tables(preview, bufnr)
                    end
                end,
                desc = "Markdown render toggle (in-place, source stays editable)",
            },
        },
        config = function()
            local preview = require("md-render").preview

            -- Eye-catching marker for ==highlight== text: the plugin default
            -- (dark olive bg + pale yellow fg) is near-invisible on dark
            -- themes. Non-default definition wins over the plugin's
            -- default=true re-application on every session rebuild.
            vim.api.nvim_set_hl(0, "MdRenderHighlight", { bold = true, fg = "#1e1e2e", bg = "#f9e2af" })

            -- Pipe-table cells: render <br> as a real line break by splitting
            -- the row into continuation sub-rows before table rendering. The
            -- plugin only handles <br> in HTML <dt>/<dd>, not in pipe tables.
            local md_table = require("md-render.markdown_table")
            local function split_br_segments(text)
                local segs = vim.split(text, "<[bB][rR]%s*/?>")
                while #segs > 1 and segs[1] == "" do table.remove(segs, 1) end
                while #segs > 1 and segs[#segs] == "" do table.remove(segs) end
                return segs
            end
            local function row_has_br(cells)
                for _, c in ipairs(cells) do
                    if c.text and c.text:match("<[bB][rR]%s*/?>") then return true end
                end
                return false
            end
            -- Original highlights/links are positioned against the full cell
            -- text; keep only those starting within the kept segment (the
            -- plugin clamps end positions itself).
            local function clip_highlights(hls, max_bytes)
                local out = {}
                for _, h in ipairs(hls or {}) do
                    if (h.col or 0) <= max_bytes then out[#out + 1] = h end
                end
                return out
            end
            local function clip_links(links, max_bytes)
                local out = {}
                for _, l in ipairs(links or {}) do
                    if (l.col_start or 0) <= max_bytes then
                        out[#out + 1] = vim.tbl_extend("force", l, {
                            col_end = math.min(l.col_end or 0, max_bytes),
                        })
                    end
                end
                return out
            end
            local function split_row_cells(cells)
                local seg_lists, n = {}, 1
                for col, c in ipairs(cells) do
                    local segs = split_br_segments(c.text or "")
                    seg_lists[col] = segs
                    n = math.max(n, #segs)
                end
                local out = {}
                for k = 1, n do
                    local row = {}
                    for col, c in ipairs(cells) do
                        local seg = seg_lists[col][k] or ""
                        local len = #seg
                        row[col] = {
                            text = seg,
                            highlights = k == 1 and clip_highlights(c.highlights, len) or {},
                            links = k == 1 and clip_links(c.links, len) or {},
                        }
                    end
                    out[k] = row
                end
                return out
            end
            local function expand_table_br(parsed)
                if not row_has_br(parsed.headers) then
                    local any = false
                    for _, row in ipairs(parsed.rows) do
                        if row_has_br(row) then any = true break end
                    end
                    if not any then return parsed end
                end
                parsed.headers = (function()
                    local hs = {}
                    for col, c in ipairs(parsed.headers) do
                        local text = table.concat(split_br_segments(c.text or ""), " ")
                        hs[col] = {
                            text = text,
                            highlights = clip_highlights(c.highlights, #text),
                            links = clip_links(c.links, #text),
                        }
                    end
                    return hs
                end)()
                local new_rows = {}
                for _, row in ipairs(parsed.rows) do
                    for _, sub in ipairs(split_row_cells(row)) do
                        new_rows[#new_rows + 1] = sub
                    end
                end
                parsed.rows = new_rows
                local widths = {}
                for col in ipairs(parsed.alignments) do
                    local w = vim.api.nvim_strwidth(parsed.headers[col].text)
                    for _, row in ipairs(parsed.rows) do
                        local c = row[col]
                        if c then w = math.max(w, vim.api.nvim_strwidth(c.text)) end
                    end
                    widths[col] = w
                end
                parsed.col_widths = widths
                return parsed
            end
            local orig_table_render = md_table.render
            md_table.render = function(parsed, ...)
                return orig_table_render(expand_table_br(parsed), ...)
            end

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
