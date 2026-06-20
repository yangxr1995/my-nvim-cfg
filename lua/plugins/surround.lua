return {
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = function()
            -- 快捷键一览（nvim-surround v4 默认）：
            --   添加环绕    ys{motion}{char}   例: ysiw"  给单词加引号
            --   删除环绕    ds{char}           例: ds)    删除括号
            --   修改环绕    cs{target}{new}    例: cs"'   引号改单引号
            --   可视模式    S{char}            选中后按 S 加环绕
            --   嵌套计数    3dsq               删除三层引号
            --   函数环绕    ysiwf              自动询问函数名
            --   HTML 标签   ysiwt              自动询问标签名
            --   别名缩写:
            --     b -> )   B -> {   r -> ]   a -> <
            --     q -> "'` 循环    s -> }])>"'` 循环
            local status_ok, surround = pcall(require, "nvim-surround")
            if not status_ok then
                return
            end

            surround.setup({
                -- 字符别名（常用字符缩写）
                aliases = {
                    ["a"] = ">",                 -- sa -> < >
                    ["b"] = ")",                 -- sb -> ( )
                    ["B"] = "}",                 -- sB -> { }
                    ["r"] = "]",                 -- sr -> [ ]
                    ["q"] = { '"', "'", "`" },   -- sq 循环切换三种引号
                    ["s"] = { "}", "]", ")", ">", '"', "'", "`" }, -- ss 循环切换多种定界符
                    ["t"] = ">",                 -- st -> < >
                },
                -- 操作高亮持续时间（毫秒）
                highlight = {
                    duration = 50,
                },
            })
        end,
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true,
    },
}
