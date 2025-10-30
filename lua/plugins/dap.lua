return {
    {
        'mfussenegger/nvim-dap',
        dependencies = {
            'theHamsta/nvim-dap-virtual-text',
            'rcarriga/nvim-dap-ui',
            'nvim-telescope/telescope-dap.nvim',
        },
        -- lazy = true,
        -- event = {"VeryLazy"},
        keys = {
            { "<leader>d", "", desc = "+debug", mode = { "n", "v" } },
            { '<F5>', function() require 'telescope'.extensions.dap.configurations {} end, { desc = "开始调试" } },
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "条件断点" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "添加/删除断点" },
            { "<leader>do", function() require("dap").step_over() end, desc = "单步" },
            { "<leader>dc", function() require("dap").run_to_cursor() end, desc = "运行到光标处" },
            { "<leader>di", function() require("dap").step_into() end, desc = "入函数" },
            { "<leader>dO", function() require("dap").step_out() end, desc = "出函数" },
            { "<leader>dC", function() require("dap").continue() end, desc = "继续运行" },

            { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
            { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },

            { "<leader>dj", function() require("dap").down() end, desc = "切换到下一个breakpoint" },
            { "<leader>dk", function() require("dap").up() end, desc = "切换到上一个breakpoint" },

            -- { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
            { "<leader>dp", function() require("dap").pause() end, desc = "暂停线程" },
            -- { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
            { "<leader>ds", function() require("dap").session() end, desc = "Session" },
            { "<leader>dT", function() require("dap").terminate() end, desc = "终止调试" },
            -- { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
        },

        config = function()
            local dap = require("dap")

            dap.adapters.gdb = {
                type = "executable",
                command = "gdb",
                args = { "--interpreter=dap",
                        "--eval-command", "set print pretty on",
                }
            }

            dap.adapters.gdb_aarch64 = {
                type = "executable",
                command = "gdb-multiarch",
                args = { "--interpreter=dap",
                        "--eval-command", "set-architecture aarch64",
                        "--eval-command", "set print pretty on",
                }
            }

            dap.configurations.c = {
                {
                    name = "Launch",
                    type = "gdb",
                    request = "launch",
                    program = function()
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    args = {}, -- provide arguments if needed
                    cwd = "${workspaceFolder}",
                    stopAtBeginningOfMainSubprogram = false,
                },
                {
                    name = "Select and attach to process",
                    type = "gdb",
                    request = "attach",
                    program = function()
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    pid = function()
                        local name = vim.fn.input('Executable name (filter): ')
                        return require("dap.utils").pick_process({ filter = name })
                    end,
                    cwd = '${workspaceFolder}'
                },
                {
                    name = 'Attach to gdbserver :1234',
                    type = 'gdb',
                    request = 'attach',
                    target = 'localhost:1234',
                    program = function()
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}'
                },
                {
                    name = 'Attach to gdbserver :1234',
                    type = 'gdb_aarch64',
                    request = 'attach',
                    target = 'localhost:1234',
                    program = function()
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}'
                }
            }
        end
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio", "folke/neodev.nvim" },
        keys = {
            { "<leader>du", function() require("dapui").toggle({}) end, desc = "打开/关闭UI" },
            { "<leader>de", function() require("dapui").eval() end, desc = "查询值", mode = { "n", "v" } },
        },
        lazy = true,
        event = {"VeryLazy"},
        opts = {},
        config = function()
            local dap, dapui = require("dap"), require("dapui")
            dapui.setup({
                expand_lines = true,
                icons = { expanded = "", collapsed = "", circular = "" },
                mappings = {
                    -- Use a table to apply multiple mappings
                    expand = { "<CR>", "<2-LeftMouse>" },
                    open = "o",
                    remove = "d",
                    edit = "e",
                    repl = "r",
                    toggle = "t",
                },
                layouts = {
                    {
                        elements = {
                            { id = "scopes",      size = 0.33 },
                            { id = "breakpoints", size = 0.17 },
                            { id = "stacks",      size = 0.25 },
                            { id = "watches",     size = 0.25 },
                        },
                        size = 0.33,
                        position = "right",
                    },
                    {
                        elements = {
                            { id = "repl",    size = 0.45 },
                            { id = "console", size = 0.55 },
                        },
                        size = 0.27,
                        position = "bottom",
                    },
                },
                floating = {
                    max_height = 0.9,
                    max_width = 0.5,             -- Floats will be treated as percentage of your screen.
                    border = vim.g.border_chars, -- Border style. Can be 'single', 'double' or 'rounded'
                    mappings = {
                        close = { "q", "<Esc>" },
                    },
                },
            })
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end
        end,
    },
    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = {
            "mfussenegger/nvim-dap",
        },
        lazy = true,
        event = {"VeryLazy"},
        config = function()
            require("nvim-dap-virtual-text").setup {
                enabled = true,                     -- enable this plugin (the default)
                enabled_commands = true,            -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
                highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
                highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
                show_stop_reason = true,            -- show stop reason when stopped for exceptions
                commented = false,                  -- prefix virtual text with comment string
                only_first_definition = true,       -- only show virtual text at first definition (if there are multiple)
                all_references = false,             -- show virtual text on all all references of the variable (not only definitions)
                clear_on_continue = false,          -- clear virtual text on "continue" (might cause flickering when stepping)
                --- A callback that determines how a variable is displayed or whether it should be omitted
                --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
                --- @param buf number
                --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
                --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
                --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
                --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
                display_callback = function(variable, buf, stackframe, node, options)
                    -- by default, strip out new line characters
                    if options.virt_text_pos == 'inline' then
                        return ' = ' .. variable.value:gsub("%s+", " ")
                    else
                        return variable.name .. ' = ' .. variable.value:gsub("%s+", " ")
                    end
                end,
                -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
                virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',

                -- experimental features:
                all_frames = false,     -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
                virt_lines = false,     -- show virtual lines instead of virtual text (will flicker!)
                virt_text_win_col = nil -- position the virtual text at a fixed window column (starting from the first text column) ,
                -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
            }
        end
    },
    {
        "nvim-telescope/telescope-dap.nvim",
        dependencies = { "mfussenegger/nvim-dap" },
        keys = {
            { '<F5>', function() require 'telescope'.extensions.dap.configurations {} end, { desc = "开始调试" } },
            { "<leader>dtb", function() require("telescope").extensions.dap.list_breakpoints {} end, {desc = "查看断点"} },
            { "<leader>dtv", function() require("telescope").extensions.dap.variables {} end, {desc = "查看变量"} },
            { "<leader>dtf", function() require("telescope").extensions.dap.frames {} end, {desc = "查看栈"} },
        },
        config = function()
            require("telescope").setup()
        end
    }
}
