local live_grep_c = function()
    require("telescope.builtin").live_grep({
        additional_args = { "-g", "*.{c,h,cc,cpp,hpp}" },
        prompt_title = "Live Grep (C/Cpp)",
    })
end

local function find_files_with_config()
    local default_dirs = { "./" }
    local search_dirs = default_dirs

    local config_file = "./find_files"
    local ok, file = pcall(io.open, config_file, "r")
    if file then
        local content = file:read("*all")
        file:close()

        local success, data = pcall(vim.json.decode, content)
        if success and type(data) == "table" and data.search_dirs then
            search_dirs = data.search_dirs
        else
            search_dirs = {}
            for line in content:gmatch("[^\r\n]+") do
                line = line:match("^%s*(.-)%s*$")
                if line ~= "" and line:sub(1, 1) ~= "#" then
                    table.insert(search_dirs, line)
                end
            end
            if #search_dirs == 0 then
                search_dirs = default_dirs
            end
        end
    end

    require("telescope.builtin").find_files({
        search_dirs = search_dirs,
    })
end

local live_grep_gtags = function()
    local file = io.open("gtags-list", "r")
    if not file then
        print("gtags-list 文件不存在")
        return
    end

    local file_list = {}
    for line in file:lines() do
        table.insert(file_list, line)
    end
    file:close()

    require("telescope.builtin").live_grep({
        prompt_title = "Live Grep (gtags)",
        search_dirs = file_list,
    })
end

return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-lua/popup.nvim",
        "nvim-telescope/telescope-file-browser.nvim",
        "nvim-telescope/telescope-media-files.nvim",
        "nvim-telescope/telescope-symbols.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release" },
    },
    keys = {
        { "rra", function() require("telescope.builtin").live_grep() end,                           desc = "live grep" },
        { "rrc", live_grep_c,                                                                       desc = "live grep C/Cpp" },
        { "rrg", live_grep_gtags,                                                                   desc = "live grep gtags" },
        { "rfa", function() require("telescope.builtin").find_files() end,                           desc = "find files all" },
        { "rff", find_files_with_config,                                                            desc = "find files with filter" },
        { "rs",  function() require("telescope.builtin").lsp_dynamic_workspace_symbols() end,        desc = "find lsp symbols" },
    },
    lazy = true,
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup({
            defaults = {
                layout_strategy = "cursor",
                layout_config = { height = 0.90, width = 0.98 },

                prompt_prefix = " ",
                selection_caret = " ",
                path_display = { "smart" },

                mappings = {
                    i = {
                        ["<C-n>"] = actions.cycle_history_next,
                        ["<C-p>"] = actions.cycle_history_prev,

                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,

                        ["<C-c>"] = actions.close,

                        ["<Down>"] = actions.move_selection_next,
                        ["<Up>"] = actions.move_selection_previous,

                        ["<CR>"] = actions.select_default,
                        ["<C-x>"] = actions.select_horizontal,
                        ["<C-v>"] = actions.select_vertical,
                        ["<C-t>"] = actions.select_tab,

                        ["<C-u>"] = actions.preview_scrolling_up,
                        ["<C-d>"] = actions.preview_scrolling_down,

                        ["<PageUp>"] = actions.results_scrolling_up,
                        ["<PageDown>"] = actions.results_scrolling_down,

                        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                        ["<C-l>"] = actions.complete_tag,
                        ["<C-_>"] = actions.which_key,
                    },

                    n = {
                        ["<esc>"] = actions.close,
                        ["<CR>"] = actions.select_default,
                        ["<C-x>"] = actions.select_horizontal,
                        ["<C-v>"] = actions.select_vertical,
                        ["<C-t>"] = actions.select_tab,

                        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

                        ["j"] = actions.move_selection_next,
                        ["k"] = actions.move_selection_previous,
                        ["H"] = actions.move_to_top,
                        ["M"] = actions.move_to_middle,
                        ["L"] = actions.move_to_bottom,

                        ["<Down>"] = actions.move_selection_next,
                        ["<Up>"] = actions.move_selection_previous,
                        ["gg"] = actions.move_to_top,
                        ["G"] = actions.move_to_bottom,

                        ["<C-u>"] = actions.preview_scrolling_up,
                        ["<C-d>"] = actions.preview_scrolling_down,

                        ["<PageUp>"] = actions.results_scrolling_up,
                        ["<PageDown>"] = actions.results_scrolling_down,

                        ["?"] = actions.which_key,
                    },
                },
            },

            extensions = {
                media_files = {
                    filetypes = { "png", "webp", "jpg", "jpeg" },
                    find_cmd = "rg",
                },
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },
            },
        })

        telescope.load_extension("media_files")
    end,
}
