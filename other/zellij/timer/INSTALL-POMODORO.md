# Zellij 番茄钟 + 实时时钟 + 定时闹钟 安装指南

> 面向 agent / 自动化安装。适用于 **zellij 0.44.x**（在 0.44.3 端到端验证）。
> 一键安装：`bash ~/.config/zellij/install-pomodoro.sh`（幂等，可重复执行）

## 最终效果

| 功能 | 实现 | 使用方式 |
|------|------|----------|
| 番茄钟 | zj-pomodoro（自编译 + 到期通知补丁 + **跨 session 持久化补丁**） | `Alt z` → Enter 确认（默认 25 分钟工作 / 5 分钟休息） |
| 倒计时显示 | zj-barename 顶栏 | 番茄钟运行时显示 `W mm:ss [streak]`；**所有 session 的顶栏同步显示同一倒计时** |
| 实时时钟 | zj-barename 顶栏右侧（+08:00，已打源码补丁） | 自动显示 |
| 到期通知 | notify-send 系统通知（源码补丁新增） | 到期自动触发 + 界面菜单（b 休息 / w 继续 / c 取消 / Esc 10 秒后再弹） |
| 定时闹钟 | `at` + notify-send | `echo 'notify-send "闹钟" "时间到"' | at 15:00` |

## 环境要求

- zellij 0.44.x（`zellij --version`）
- rustup + cargo（wasm 交叉编译）
- python3（补丁脚本）
- git、curl
- notify-send（通知功能，需 dunst/mako 等通知守护进程；无头服务器通知会静默失败，界面菜单仍可见）
- `at`（可选，定时闹钟；apt 系统脚本自动安装）

## 关键背景（为什么不是直接装原插件）

1. **tw4452852/zellij-pomodoro-plugin（2022 年停更）的 release wasm 与 zellij 0.40+ 不兼容**
   加载报错 `cannot find definition for import zellij::host_subscribe`。zellij 0.40 重写了插件 API
   （protobuf 通信 + 权限系统），旧产物无法运行，也无任何 fork 完成移植。
2. **替代方案**：bihari123/zj-pomodoro（构建于 zellij-tile 0.44.3）+ 同作者的 zj-barename（顶栏渲染倒计时）。
   两者均无暂停/恢复功能（只有停止重置），zj-pomodoro 无到期通知 → 脚本通过源码补丁补齐。
3. **zellij 0.44.3 已知 bug：会话首 tab 的 plugin 配置丢失**。
   `default_tab_template` 内联配置、config.kdl `plugins` 别名配置、tab 级内联配置——凡是"会话首 tab"
   加载的插件一律收不到配置（运行中会话 `new-tab --layout <file>` 显式加载则正常）。
   ⇒ **布局中的 bar 插件绝不能依赖 layout 内联配置**，本方案所有行为都在源码层固定。
   表面症状举例：zjstatus 时钟固定显示 IST（UTC+5:30），清缓存/换布局写法均无效。
4. **zellij 0.40+ 插件实例随客户端 attach 重建（跨 session 补丁的根因）**。
   插件实例是 per-(PluginId, ClientId) 的，每次 attach（含切换 session 后切回）都会创建全新
   WASM 实例并重跑 `load()`，插件内存状态归零——这就是"切换 session 后番茄钟被取消"的根因。
   另外 zellij 的插件广播（pipe）只在单个 session 内传播，别的 session 天生看不到计时。
   ⇒ 解法：计时真值落盘 `/cache`（zellij 为每个插件 URL 无条件挂载的稳定目录
   `~/.cache/zellij/<url>/plugin_cache/`），各 session 实例通过 owner_nonce + heartbeat
   选主对账（10s 一轮），owner 失联（session detach/退出）后由其他实例接管到期通知与菜单。

### 跨 session 机制速览（补丁 4c）

```text
状态文件   /cache/zj-pomodoro.state（插件内路径；宿主为 ~/.cache/zellij/file:…/plugin_cache/）
格式       status|end|streak|work_mins|break_mins|owner_nonce|heartbeat
           status ∈ off | work | break | done（done=边界已报告待应答）
角色       控制实例（owner）：写心跳、到期时 notify-send + 弹菜单
           跟随实例（follower）：只读对账，向本 session 顶栏广播倒计时
接管       owner 心跳停跳 >25s（= session detach/退出）后，最先发现的新实例原子换写
           owner_nonce 完成接管；到期边界以文件中的绝对时间戳计算，睡眠/休眠也正确
任意 session  Alt z 均为对全局番茄钟的操作（启动/停止都会写回状态文件）
```

注意：**不要**给插件新增 permissions.kdl 缓存之外的权限（如 FullHdAccess）——后台插件的
授权框弹不出来（zellij#4982），新权限会被整体拒绝并连累已授权项。/cache 挂载不需要任何
文件权限（plugin_loader.rs `create_wasi_ctx` 无条件挂载 /host /data /cache /tmp）。

## 手动安装步骤（等价于脚本内容）

```bash
# 0. 前置
command -v zellij cargo rustup python3   # 缺一不可
rustup target add wasm32-wasip1
[ apt 系统可选 ] apt-get install -y at

# 1. 克隆源码
git clone --depth 1 https://github.com/bihari123/zj-pomodoro   /tmp/zellij-pomodoro-build/zj-pomodoro
git clone --depth 1 https://github.com/bihari123/zj-barename   /tmp/zellij-pomodoro-build/zj-barename

# 2. 补丁 A —— zj-pomodoro 到期通知（两处修改 src/main.rs）
#    2a. load() 中 request_permission 数组追加一行：
#            PermissionType::RunCommands,
#    2b. update() 中 Event::Timer 到期分支首行插入：
#            run_command(&["notify-send", "Pomodoro", "番茄钟计时结束"], BTreeMap::new());
#    精确锚点见 install-pomodoro.sh 第 4 节（python 补丁，锚点失配会显式报错）

# 2c. 补丁 C —— zj-pomodoro 跨 session 状态持久化（install-pomodoro.sh 第 4c 节）
#     约 290 行：状态文件读写（/cache）、owner_nonce+heartbeat 选主、10s 对账循环。
#     由脚本自动应用；手工操作直接执行脚本第 4c 节的 python 补丁即可。

# 3. 补丁 B —— zj-barename 时钟默认时区（src/main.rs 一处）
#    .unwrap_or(19800)  →  .unwrap_or(28800)   # +05:30 → +08:00

# 3b. 补丁 D —— zj-barename 未选中 tab 背景（src/tab.rs 一处）
#     上游硬编码红色 INACTIVE_TAB_BG #d03333（主题无法覆盖）→ 暗蓝 #1a3380
#     PaletteColor::Rgb((0xd0, 0x33, 0x33)) → PaletteColor::Rgb((0x1a, 0x33, 0x80))
#     完整可执行步骤（换色/其他环境 agent）：见同目录 PATCH-TAB-COLOR.md

# 4. 编译并安装
cd /tmp/zellij-pomodoro-build/zj-pomodoro && cargo build --release --target wasm32-wasip1
cp target/wasm32-wasip1/release/*.wasm ~/.config/zellij/plugins/zj-pomodoro.wasm
cd ../zj-barename && cargo build --release --target wasm32-wasip1
cp target/wasm32-wasip1/release/tab-bar.wasm ~/.config/zellij/plugins/zj-barename.wasm

# 5. 布局 ~/.config/zellij/layouts/default.kdl
#    内容见 install-pomodoro.sh 第 8 节（tab 级结构，bar 不依赖任何内联配置）

# 6. config.kdl（备份后修改）
#    - load_plugins 段加入 zj-pomodoro.wasm（work_mins "25" / break_mins "5"）
#    - 快捷键绑定（插到 bind "Alt x" { Quit; } 之前）：
#        bind "Alt z" {
#            MessagePlugin {
#                name "pomodoro_toggle"
#            }
#        }

# 7. 预写权限缓存 ~/.cache/zellij/permissions.kdl（避免首次弹确认框）
#    格式见 install-pomodoro.sh 第 10 节

# 8. 验证 wasm ABI（应只含新 API 导入，详见脚本第 7 节）
```

## 源码补丁详情

### A. zj-pomodoro（bihari123/zj-pomodoro, zellij-tile 0.44.3）

```diff
--- src/main.rs
+++ src/main.rs（load() 内）
     request_permission(&[
         PermissionType::ChangeApplicationState,
         PermissionType::MessageAndLaunchOtherPlugins,
+        PermissionType::RunCommands,     // 到期通知需要
     ]);

--- src/main.rs
+++ src/main.rs（update() 内 Event::Timer 处理）
             } else if self.status != Status::Off && now_secs() >= self.end {
+                run_command(&["notify-send", "Pomodoro", "番茄钟计时结束"], BTreeMap::new());
                 self.pending_boundary = Some(self.status);
                 self.surface_menu();
             }
```

注意：只加在**到期分支**（`now_secs() >= self.end`）。上游用 `pending_boundary` 防重，
未应答时每 60 秒走的是另一个分支（`pending_boundary.is_some()`），不要把通知加在那里。
（打补丁 C 后该分支被 10s 对账循环 `tick()` 整体替代，通知逻辑移入 `fire_boundary()`。）

### C. zj-pomodoro 跨 session 状态持久化（install-pomodoro.sh 第 4c 节）

机制见上文"跨 session 机制速览"。要点：

- `Event::Timer` 处理臂整体替换为 `tick()`（10s 周期对账：控制者写心跳+到期边界；
  跟随者只读对账；owner 心跳失联 >25s 由最先发现者原子接管）
- `start_session()` / `stop()` 落盘；`toggle()` 操作前先对账全局状态
- `load()` 认领实例身份（nonce）并**静默**对账（load 期 zellij 权限尚未就绪，广播会被拒）
- 到期边界用**绝对时间戳**（`end`）计算，实例重建/系统睡眠均不漂移

权限名是 **`RunCommands`**（复数），zellij 源码映射：
`PluginCommand::ExecCmd(..) => PermissionType::RunCommands`（zellij-server/src/plugins/zellij_exports.rs）。

### B. zj-barename（bihari123/zj-barename, master 分支）

```diff
--- src/main.rs
+++ src/main.rs（load() 内）
-            .unwrap_or(19800);   // +05:30，作者本地时区（印度）
+            .unwrap_or(28800);   // +08:00

--- src/tab.rs
+++ src/tab.rs（未选中 tab 背景）
-const INACTIVE_TAB_BG: PaletteColor = PaletteColor::Rgb((0xd0, 0x33, 0x33)); // 红
+const INACTIVE_TAB_BG: PaletteColor = PaletteColor::Rgb((0x1a, 0x33, 0x80)); // 暗蓝
```

该插件无 tz 数据库依赖，时钟 = unix 时间戳 + 固定秒偏移，也可用 `utc_offset` 配置覆盖——
但见上文 0.44.3 首 tab 配置丢失 bug，改默认值是最可靠的方式。

## 验证清单（headless / agent 可执行）

```bash
# 1. 配置语法
zellij setup --check 2>&1 | grep -c "Failed to parse"   # 期望 0

# 2. wasm ABI（决定性检查：出现 host_subscribe 即为旧 API 产物）
python3 -c "
import re
for p in ['$HOME/.config/zellij/plugins/zj-pomodoro.wasm']:
    names = set(re.findall(rb'zellij::[a-z_]+', open(p,'rb').read()))
    print(names)  # 应为 {b'zellij::host_run_plugin_command'}
"

# 3. 端到端（tmux 嵌套法；注意下文"tmux 测试伪影"）
tmux new-session -d -s ztest -x 220 -y 50
tmux send-keys -t ztest "zellij attach --create ztest1" Enter
sleep 10
tmux capture-pane -t ztest -p | head -1
# 期望顶栏:  (会话名) Tab #1 ... BASE HH:MM   ← 时钟为系统本地时间即正确
```

### tmux 测试伪影（重要）

tmux 内 attach zellij **之后**，`tmux send-keys` 无法再把按键送达 zellij 的 pane
（shell 命令、权限框 y、M-z 均可能失效；服务端渲染仍正常）。这是测试环境伪影，
用户真实终端不受影响。绕过方法：

```bash
# CLI 可跨会话操作（--session 指定目标，不会误伤其他会话）
zellij --session <会话名> action new-tab --layout /path/to/layout.kdl
```

## 已知限制与排障

| 现象 | 原因 | 处置 |
|------|------|------|
| 插件加载报 `cannot find import zellij::host_subscribe` | 旧 API（zellij-tile <0.40）产物 | 用本方案的源码编译产物 |
| 首个 tab 的 bar 插件忽略 layout 配置（如时区不对、显示作者默认样式） | zellij 0.44.3 首 tab 配置传递 bug | 不依赖内联配置；行为固化到源码（如本方案时区补丁） |
| 时钟显示 11:xx（比系统慢 2.5 小时） | zj-barename 上游默认 IST | 补丁 B；确认 wasm 为新编译产物 |
| 未选中 tab 又变回红色 | 上游硬编码 #d03333，重装未打改色补丁 | 补丁 D（install 脚本 5b 节）；见 `PATCH-TAB-COLOR.md`；确认 wasm 为新编译产物 |
| 到期无系统通知 | 无通知守护进程 / 未装 notify-send | 装 dunst/mako；界面菜单仍是有效提醒 |
| `Alt z` 无反应 | 会话为旧配置启动 | 开新会话；或检查 config.kdl 是否含 `pomodoro_toggle` |
| 旧 session 看不到倒计时/不能跨 session | 该会话还是补丁前的旧 wasm 实例 | 重启该会话（补丁只对新会话生效） |
| 偶发两次到期通知 | 双实例接管竞态（毫秒级窗口，罕见） | 无害，忽略即可 |
| 权限确认框反复出现 | permissions.kdl 缺条目 | 见脚本第 10 节预写；**勿手工新增缓存外权限**（见 4c 段说明） |
| 兼容性 | 仅验证 0.44.3 | 0.40-0.44 大概率可用；升级 0.45+ 前先重跑脚本并观察补丁锚点是否仍匹配（失配会显式报错而非静默跳过） |

## 文件清单

| 路径 | 说明 |
|------|------|
| `~/.config/zellij/install-pomodoro.sh` | 一键安装脚本（幂等） |
| `~/.config/zellij/INSTALL-POMODORO.md` | 本文档 |
| `~/.config/zellij/PATCH-TAB-COLOR.md` | 未选中 tab 改色：agent 可独立执行手册 |
| `~/.config/zellij/plugins/zj-pomodoro.wasm` | 番茄钟（自编译 + 通知补丁） |
| `~/.config/zellij/plugins/zj-barename.wasm` | 顶栏（自编译 + 时区补丁 + 未选中 tab 暗蓝补丁） |
| `~/.config/zellij/layouts/default.kdl` | 默认布局（bar 不依赖内联配置） |
| `~/.config/zellij/config.kdl` | `Alt z` 绑定 + `load_plugins`（有 .bak-pomodoro 备份） |
| `~/.cache/zellij/permissions.kdl` | 插件权限缓存（预写免弹窗） |
| `~/.cache/zellij/file:…zj-pomodoro.wasm/plugin_cache/zj-pomodoro.state` | 番茄钟跨 session 状态文件（自动生成，可删除重置） |

卸载：删除上述 plugins/layouts 文件，还原 config.kdl.bak-pomodoro，删除 permissions.kdl 中
对应条目即可。

## 使用速查

```text
Alt z        番茄钟菜单（数字改时长 / Enter 确认启动 / Esc 取消）
             任意 session 按均为全局操作；运行中再按 = 停止并重置 streak
             （注意：无暂停/恢复功能，上游设计如此）
顶栏         (会话名) Tab #n ... W mm:ss [streak] HH:MM   ← 所有 session 同步显示
到期         notify-send 通知 + 边界菜单：b=休息  w=继续工作  c=取消  Esc=10 秒后再提醒
             菜单弹在"控制实例"所在 session；若该 session 已切换/退出，由接管实例弹出
切换 session 计时不中断；新 attach 的 session 顶栏 10 秒内恢复倒计时显示
定时闹钟     echo 'notify-send "闹钟" "时间到"' | at 15:00
             atq 查看队列 / atrm <编号> 删除
```
