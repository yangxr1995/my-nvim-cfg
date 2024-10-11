return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSesionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      local tools = require("llm.common.tools")
      -- vim.api.nvim_set_hl(0, "Query", { fg = "#6aa84f", bg = "NONE" })
      require("llm").setup({

        -- [[ cloudflared ]]     params: api_type =  "workers.ai" | "openai" | "zhipu"
        -- model = "@cf/qwen/qwen1.5-14b-chat-awq",

        -- [[ GLM ]]
        url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        -- model = "glm-4-flash",
        model = "glm-4-plus",
        max_tokens = 8000,

        -- [[ kimi ]]
        -- url = "https://api.moonshot.cn/v1/chat/completions",
        -- model = "moonshot-v1-8k", -- "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"
        -- api_type = "openai",
        -- streaming_handler = kimi_handler,
        -- max_tokens = 4096,

        -- [[ Github Models ]]
        -- url = "https://models.inference.ai.azure.com/chat/completions",
        -- -- model = "gpt-4o",
        -- api_type = "openai",
        -- max_tokens = 4096,
        -- model = "gpt-4o-mini",

        -- [[ siliconflow ]]
        -- url = "https://api.siliconflow.cn/v1/chat/completions",
        -- model = "THUDM/glm-4-9b-chat",
        -- api_type = "openai",
        -- max_tokens = 4096,
        -- model = "Vendor-A/Qwen/Qwen2-72B-Instruct",
        -- model = "01-ai/Yi-1.5-9B-Chat-16K",
        -- model = "google/gemma-2-9b-it",
        -- model = "meta-llama/Meta-Llama-3.1-8B-Instruct",
        -- model = "Qwen/Qwen2.5-7B-Instruct",
        -- model = "Qwen/Qwen2.5-Coder-7B-Instruct",
        -- model = "internlm/internlm2_5-7b-chat",

        temperature = 0.3,
        top_p = 0.7,

        prompt = "You are a helpful chinese assistant.",

        prefix = {
          user = { text = "😃 ", hl = "Title" }, ------------ 
          assistant = { text = "  ", hl = "Added" },
        },

        save_session = true,
        max_history = 15,
        max_history_name_length = 20,

        -- stylua: ignore
        -- popup window options
        popwin_opts = {
          relative = "cursor", enter = true,
          focusable = true, zindex = 50,
          position = { row = -7, col = 15, },
          size = { height = 15, width = "50%", },
          border = { style = "single",
            text = { top = " Explain ", top_align = "center" },
          },
          win_options = {
            winblend = 0,
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },

        -- stylua: ignore
        keys = {
          -- The keyboard mapping for the input window.
          ["Input:Submit"]      = { mode = "n", key = "<cr>" },
          ["Input:Cancel"]      = { mode = {"n", "i"}, key = "<C-c>" },
          ["Input:Resend"]      = { mode = {"n", "i"}, key = "<C-r>" },

          -- only works when "save_session = true"
          ["Input:HistoryNext"] = { mode = {"n", "i"}, key = "<C-j>" },
          ["Input:HistoryPrev"] = { mode = {"n", "i"}, key = "<C-k>" },

          -- The keyboard mapping for the output window in "split" style.
          ["Output:Ask"]        = { mode = "n", key = "i" },
          ["Output:Cancel"]     = { mode = "n", key = "<C-c>" },
          ["Output:Resend"]     = { mode = "n", key = "<C-r>" },

          -- The keyboard mapping for the output and input windows in "float" style.
          ["Session:Toggle"]    = { mode = "n", key = "<leader>ac" },
          ["Session:Close"]     = { mode = "n", key = {"<esc>", "Q"} },
        },

        app_handler = {
          OptimizeCode = {
            handler = tools.side_by_side_handler,
          },
          TestCode = {
            handler = tools.side_by_side_handler,
            prompt = [[ Write some test cases for the following code, only return the test cases.
            Give the code content directly, do not use code blocks or other tags to wrap it. ]],
            opts = {
              right = {
                title = " Test Cases ",
              },
            },
          },
          OptimCompare = {
            handler = tools.action_handler,
          },
          Translate = {
            handler = tools.qa_handler,
          },

          -- check siliconflow's balance
          -- UserInfo = {
          --   handler = function()
          --     local key = os.getenv("LLM_KEY")
          --     local res = tools.curl_request_handler(
          --       "https://api.siliconflow.cn/v1/user/info",
          --       { "GET", "-H", string.format("'Authorization: Bearer %s'", key) }
          --     )
          --     if res ~= nil then
          --       print("balance: " .. res.data.balance)
          --     end
          --   end,
          -- },

        },
      })
    end,
    keys = {
      { "<leader>llc", mode = "n", "<cmd>LLMSessionToggle<cr>" },
      -- { "<leader>ae", mode = "v", "<cmd>LLMSelectedTextHandler 请解释下面这段代码<cr>" },
      { "<leader>llt", mode = "x", "<cmd>LLMSelectedTextHandler 英译汉<cr>" },
      { "<leader>llt", mode = "n", "<cmd>LLMAppHandler Translate<cr>" },
      -- { "<leader>t", mode = "x", "<cmd>LLMAppHandler TestCode<cr>" },
      -- { "<leader>ao", mode = "x", "<cmd>LLMAppHandler OptimCompare<cr>" },
      -- { "<leader>ao", mode = "x", "<cmd>LLMAppHandler OptimizeCode<cr>" },
      -- { "<leader>au", mode = "n", "<cmd>LLMAppHandler UserInfo<cr>" },
    },
  },
}
