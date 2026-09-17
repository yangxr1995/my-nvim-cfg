return {
    {
        "kevalin/mermaid.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        -- Eager load: user commands live in plugin/, and ftdetect must be on
        -- the runtimepath before a .mmd/.mermaid file is ever opened (an
        -- ft-lazyload would never trigger since the ft is detected by us).
        config = function()
            require("mermaid").setup()

            -- Open the live preview in the Windows browser (this setup runs
            -- in WSL): preview() starts the server (0.0.0.0, reachable as
            -- localhost from Windows via WSL2 port forwarding), then cmd.exe
            -- pops the default browser on the Windows side. vim.ui.open's
            -- xdg-open path is a no-op without a GUI here.
            local function open_in_browser()
                require("mermaid.preview").preview()
                local port = require("mermaid.server").port
                if not port then
                    vim.notify("Mermaid: preview server failed to start", vim.log.levels.ERROR)
                    return
                end
                local url = "http://localhost:" .. port
                vim.fn.setreg("+", url)
                local openers = {
                    "/mnt/c/Windows/System32/cmd.exe",
                    "wslview",
                }
                for _, opener in ipairs(openers) do
                    if vim.fn.executable(opener) == 1 then
                        if opener:match("cmd%.exe$") then
                            vim.fn.system({ opener, "/c", "start", "", url })
                        else
                            vim.fn.system({ opener, url })
                        end
                        vim.notify("Mermaid: browser preview " .. url, vim.log.levels.INFO)
                        return
                    end
                end
                vim.notify("Mermaid: open " .. url .. " manually (URL copied)", vim.log.levels.WARN)
            end

            -- External-viewer render: upstream's inline paths either draw
            -- nothing (chafa output captured and dropped) or fight the TUI
            -- (chafa sixel squashes aspect; terminal overlays leave
            -- artifacts). Render to a cached PNG instead and open it with
            -- swayimg on the Windows desktop via WSLg (press r in the
            -- viewer to pick up re-renders; swayimg 2.1 has no inotify
            -- reload — feh --reload is the auto-refreshing fallback), then
            -- to the Windows viewer through cmd.exe interop.

            -- Diagram theme: catppuccin-mocha to match the editor
            -- colorscheme (theme.lua), written once as a mermaid-cli config.
            local render = require("mermaid.render")
            local orig_render_file = render.render_file
            local cache_dir = vim.fn.stdpath("cache") .. "/mermaid"
            vim.fn.mkdir(cache_dir, "p")
            local theme_file = cache_dir .. "/mmdc-theme.json"
            vim.fn.writefile({
                vim.json.encode({
                    theme = "base",
                    themeVariables = {
                        darkMode = true,
                        background = "#1e1e2e",
                        primaryColor = "#313244",
                        primaryTextColor = "#cdd6f4",
                        primaryBorderColor = "#cba6f7",
                        secondaryColor = "#a6e3a1",
                        secondaryTextColor = "#cdd6f4",
                        tertiaryColor = "#f5c2e7",
                        tertiaryTextColor = "#cdd6f4",
                        lineColor = "#a6adc8",
                        textColor = "#cdd6f4",
                        nodeTextColor = "#cdd6f4",
                        mainBkg = "#313244",
                        nodeBorder = "#b4befe",
                        clusterBkg = "#181825",
                        clusterBorder = "#6c7086",
                        edgeLabelBackground = "#313244",
                        noteBkgColor = "#f9e2af",
                        noteTextColor = "#1e1e2e",
                        actorBkg = "#313244",
                        actorBorder = "#cba6f7",
                        actorTextColor = "#cdd6f4",
                        signalColor = "#cdd6f4",
                        signalTextColor = "#cdd6f4",
                        labelBoxBkgColor = "#313244",
                        labelTextColor = "#cdd6f4",
                        loopTextColor = "#cdd6f4",
                    },
                }),
            }, theme_file)

            render.render_source = function(content)
                if render.detect_capability() ~= "chafa" then
                    local svg = render.generate_svg(content)
                    if not svg.ok then return svg end
                    local res = orig_render_file(svg.svg_path)
                    pcall(os.remove, svg.svg_path)
                    return res
                end
                local png = cache_dir .. "/render.png"
                local input = os.tmpname() .. ".mmd"
                vim.fn.writefile(vim.split(content, "\n", { plain = true }), input)
                local out = vim.fn.system({
                    "mmdc", "-i", input, "-o", png,
                    "--backgroundColor", "#1e1e2e", "-c", theme_file, "--scale", "2",
                })
                local code = vim.v.shell_error
                pcall(os.remove, input)
                if code ~= 0 then
                    return { ok = false, error = "mmdc failed: " .. (out or ""):sub(1, 200) }
                end

                if vim.env.DISPLAY or vim.env.WAYLAND_DISPLAY then
                    if vim.fn.executable("swayimg") == 1 then
                        vim.fn.jobstart({ "swayimg", png }, { detach = true })
                        return { ok = true, method = "swayimg" }
                    end
                    if vim.fn.executable("feh") == 1 then
                        vim.fn.jobstart({ "feh", "--reload", "2", png }, { detach = true })
                        return { ok = true, method = "feh" }
                    end
                end
                local cmd_exe = "/mnt/c/Windows/System32/cmd.exe"
                if vim.fn.executable(cmd_exe) == 1 then
                    local winpath = vim.fn.system({ "wslpath", "-w", png }):gsub("%s+$", "")
                    vim.fn.system({ cmd_exe, "/c", "start", "", winpath })
                    if vim.v.shell_error == 0 then
                        return { ok = true, method = "windows viewer" }
                    end
                end
                return {
                    ok = false,
                    error = "No image viewer (install swayimg/feh / enable WSL interop); PNG kept at " .. png,
                }
            end

            -- Render the fenced mermaid block under the cursor in markdown
            -- buffers, without needing a separate .mmd file. Uses <leader>mm
            -- because <leader>mp/<leader>mr already belong to md-render.
            local function render_md_block()
                local cursor = vim.api.nvim_win_get_cursor(0)[1]
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local start = nil
                for i, line in ipairs(lines) do
                    if start then
                        if line:match("^```") or line:match("^~~~") then
                            if cursor >= start and cursor <= i then
                                local block = {}
                                for j = start + 1, i - 1 do
                                    block[#block + 1] = lines[j]
                                end
                                local content = table.concat(block, "\n")
                                if content:match("%S") then
                                    return require("mermaid.render").render_source(content)
                                end
                                vim.notify("Mermaid: block under cursor is empty", vim.log.levels.WARN)
                                return { ok = false }
                            end
                            start = nil
                        end
                    elseif line:match("^```+%s*mermaid%s*$") or line:match("^```+%s*mermaid%s+%S")
                        or line:match("^~~~+%s*mermaid%s*$") or line:match("^~~~+%s*mermaid%s+%S") then
                        start = i
                    end
                end
                vim.notify("Mermaid: cursor is not inside a ```mermaid block", vim.log.levels.WARN)
                return { ok = false }
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = function(args)
                    vim.keymap.set("n", "<leader>mm", render_md_block, {
                        buffer = args.buf,
                        silent = true,
                        desc = "Render mermaid block under cursor",
                    })
                end,
            })

            -- Buffer-local keymaps on mermaid buffers only, so they shadow
            -- (not clash with) the global <leader>mp/<leader>mr md-render
            -- mappings from markdown.lua.
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "mermaid",
                callback = function(args)
                    local map = function(lhs, cmd, desc)
                        vim.keymap.set("n", lhs, cmd, { buffer = args.buf, silent = true, desc = desc })
                    end
                    map("<leader>mp", "<cmd>MermaidPreview<CR>", "Mermaid Preview")
                    map("<leader>mo", open_in_browser, "Mermaid Preview in Windows Browser")
                    map("<leader>mf", "<cmd>MermaidFormat<CR>", "Mermaid Format")
                    map("<leader>mr", "<cmd>MermaidRender<CR>", "Mermaid Render")
                    map("<leader>mc", "<cmd>MermaidCopyURL<CR>", "Mermaid Copy URL")
                    map("<leader>mx", "<cmd>MermaidPreviewStop<CR>", "Mermaid Stop Preview")
                end,
            })
        end,
    },
}
