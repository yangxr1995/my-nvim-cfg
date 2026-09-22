# Zellij 未选中 Tab 改色指南（Agent 可执行）

> 目标：把顶栏 **未选中 tab** 的背景色从红改为蓝（或任意 RGB）。
> 适用：zellij 0.44.x + 本机 `zj-barename` 顶栏插件（魔改 tab-bar）。
> 读者：在其他环境执行本改动的 agent / 自动化脚本。

## 0. 先读：为什么改 config.kdl 无效

未选中 tab 的颜色 **不是** Zellij 主题（`themes` / `ribbon_unselected`）控制的。

上游 `bihari123/zj-barename` 在 `src/tab.rs` 里硬编码：

```rust
// 上游默认（红）
const INACTIVE_TAB_BG: PaletteColor = PaletteColor::Rgb((0xd0, 0x33, 0x33)); // #d03333
const INACTIVE_TAB_FG: PaletteColor = PaletteColor::Rgb((0xff, 0xff, 0xff));
```

`render_tab()` 对 `!tab.active` 直接用 `INACTIVE_TAB_BG`，**忽略主题 palette**。

⇒ 唯一改法：改源码 → 重编 wasm → 替换插件 → **重启会话**。

| 途径                     | 能否改未选中 tab 背景 |
| ------------------------ | --------------------- |
| `config.kdl` themes      | 否                    |
| 终端配色                 | 否（插件发 truecolor） |
| 改 `src/tab.rs` + 重编   | **是**                    |

---

## 1. 前置条件

```bash
command -v zellij cargo rustup git curl python3
rustup target add wasm32-wasip1   # 已装则跳过
zellij --version                   # 期望 0.44.x
```

目标安装路径（按环境调整，下称 `$PLUGIN`）：

```bash
PLUGIN="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/plugins/zj-barename.wasm"
```

---

## 2. 推荐路径：一键脚本（本仓库已有）

若目标环境已有 `install-pomodoro.sh`（含时区 + 改色全部补丁）：

```bash
bash "${XDG_CONFIG_HOME:-$HOME/.config}/zellij/install-pomodoro.sh"
```

脚本第 **5b** 节会幂等打上改色补丁（见下文锚点），第 **6** 节编译安装。

只想确认/改目标色时，读脚本锚点段即可，不必重装番茄钟全流程。

---

## 3. 最小路径：仅改色（无本仓库脚本时）

### 3.1 取源码

```bash
BUILD=/tmp/zj-barename-color
rm -rf "$BUILD"
mkdir -p "$BUILD"
curl -fL --retry 3 --max-time 90 \
  -o "$BUILD/src.tgz" \
  https://codeload.github.com/bihari123/zj-barename/tar.gz/refs/heads/master
tar -xzf "$BUILD/src.tgz" -C "$BUILD"
mv "$BUILD"/zj-barename-master "$BUILD/zj-barename"
```

> 若 `git clone` 网络不稳，优先 codeload tarball（本环境实测 clone 会断，tarball 可用）。

### 3.2 改色（唯一必改点）

文件：`$BUILD/zj-barename/src/tab.rs`  
锚点（grep 必须命中其一）：

| 状态     | 字面量                                    |
| -------- | ----------------------------------------- |
| 上游红   | `PaletteColor::Rgb((0xd0, 0x33, 0x33))`     |
| 旧亮蓝   | `PaletteColor::Rgb((0x33, 0x66, 0xd0))`     |
| 目标暗蓝 | `PaletteColor::Rgb((0x1a, 0x33, 0x80))` ← 当前默认 |

示例（sed 幂等，兼容红/亮蓝中间态）：

```bash
TAB_RS="$BUILD/zj-barename/src/tab.rs"
# 目标色自行替换（R,G,B 十六进制，不带 #）
NEW_R=0x1a; NEW_G=0x33; NEW_B=0x80
NEW="PaletteColor::Rgb(($NEW_R, $NEW_G, $NEW_B))"

if grep -qF "$NEW" "$TAB_RS"; then
  echo "已是指定色，跳过"
else
  sed -i \
    -e "s/PaletteColor::Rgb((0xd0, 0x33, 0x33))/$NEW/" \
    -e "s/PaletteColor::Rgb((0x33, 0x66, 0xd0))/$NEW/" \
    "$TAB_RS"
fi
grep -qF "$NEW" "$TAB_RS" || { echo "改色失败：锚点未命中" >&2; exit 1; }
```

可读性：前景保持 `INACTIVE_TAB_FG = (0xff, 0xff, 0xff)` 白字即可；若目标色很浅，可同步改 FG。

### 3.3 时区补丁（从上游全新克隆时建议一并打）

否则顶栏时钟会退回印度时区 +05:30（本机曾因 0.44.3 首 tab 配置丢失 bug 固化为源码默认）。

```bash
MAIN_RS="$BUILD/zj-barename/src/main.rs"
# 锚点：.unwrap_or(19800)  →  .unwrap_or(28800)   (+05:30 → +08:00)
if ! grep -q 'unwrap_or(28800)' "$MAIN_RS"; then
  sed -i 's/\.unwrap_or(19800)/.unwrap_or(28800)/' "$MAIN_RS"
fi
grep -q 'unwrap_or(28800)' "$MAIN_RS" || { echo "时区补丁失败" >&2; exit 1; }
```

> 其他时区：改 `28800` 为 `utc_offset` 秒数（东八区 = 8*3600）。

### 3.4 编译 + 安装

```bash
cd "$BUILD/zj-barename"
cargo build --release --target wasm32-wasip1
# 产物名固定为 tab-bar.wasm（Cargo package name = "tab-bar"）
cp -a "$PLUGIN" "${PLUGIN}.bak" 2>/dev/null || true
cp -f target/wasm32-wasip1/release/tab-bar.wasm "$PLUGIN"
chmod +x "$PLUGIN"
```

### 3.5 验证（全部通过才算完成）

```bash
# 1) 配置仍可解析
zellij setup --check 2>&1 | grep -q 'Well defined' && echo config_OK

# 2) ABI：只允许新 API，禁止 host_subscribe
python3 - <<'PY'
import os, re
p = os.path.expanduser("~/.config/zellij/plugins/zj-barename.wasm")
d = open(p, "rb").read()
assert b"host_run_plugin_command" in d, "缺少新 API 导入"
assert b"host_subscribe" not in d, "仍是旧 API"
print("abi_OK", len(d))
PY

# 3) 颜色字节码（WASM i32.const 为 LEB128，不能直接搜 RGB 原始三字节）
#    暗蓝 0x1a,0x33,0x80 → 指令序列附近应同时出现 i32.const 26 / 51 / 128
python3 - <<'PY'
import os
d = open(os.path.expanduser("~/.config/zellij/plugins/zj-barename.wasm"), "rb").read()
c26, c51, c128 = bytes.fromhex("411a"), bytes.fromhex("4133"), bytes.fromhex("418001")
old_red = bytes.fromhex("41d001211c4133211a")  # 旧红构造片段
found = False
i = 0
while True:
    i = d.find(c26, i)
    if i < 0: break
    w = d[max(0,i-48):i+48]
    if c51 in w and c128 in w:
        found = True; break
    i += 1
assert found, "未找到暗蓝常量邻域"
assert d.find(old_red) < 0, "仍含旧红构造"
print("color_OK")
PY
```

### 3.6 生效与回滚

```bash
# 生效：退出当前 zellij 会话后重新 attach / 新开 session（旧实例仍跑旧 wasm）
# 回滚：
# cp -f "$PLUGIN.bak" "$PLUGIN"   # 若 3.4 做过备份
# 或恢复上游红后重编：
# sed -i 's/PaletteColor::Rgb((0x1a, 0x33, 0x80))/PaletteColor::Rgb((0xd0, 0x33, 0x33))/' "$TAB_RS"
```

---

## 4. 换任意颜色时的检查单

1. 改 `NEW_R/NEW_G/NEW_B`（或直接改 `tab.rs` 常量）。
2. 重跑 3.4 编译安装。
3. 重跑 3.5：步骤 3 的 LEB128 期望值需同步改（`i32.const` 十进制分量）：
   - `0x1a=26 → 411a`，`0x33=51 → 4133`，`0x80=128 → 418001`
   - 例：`#3366d0` → 分量 51/102/208 → `4133` / `41e600` / `41d001`
4. 同步本目录 `install-pomodoro.sh` 第 5b 节锚点与 `INSTALL-POMODORO.md` 补丁 D（若该环境要保持脚本幂等）。
5. 重启会话，肉眼确认顶栏未选中 tab。

---

## 5. 失败排查

| 现象                         | 原因                                | 处置                              |
| ---------------------------- | ----------------------------------- | --------------------------------- |
| `改色失败：锚点未命中`         | 上游改了 `tab.rs` 或已自定义常量      | 打开源码搜 `INACTIVE_TAB_BG` 手改 |
| 颜色没变                     | 会话未重启 / 加载了缓存 wasm        | 退出会话重 attach；清 `~/.cache/zellij` 对应插件缓存可选 |
| 仍是旧 API `host_subscribe`  | 编译目标或依赖不对                  | `rustup target add wasm32-wasip1`；依赖锁定 `zellij-tile = "0.44.3"` |
| 时钟回到 11:xx               | 未打时区补丁                       | 3.3：`19800 → 28800`                |
| 网络 clone 失败              | GitHub git 协议不稳                | 改用 codeload tarball（3.1）      |
| 主题改了但 tab色不变         | 正常：主题管不到该常量             | 只能走本文件流程                  |

---

## 6. 相关文件索引（本机）

| 路径                                   | 说明                                     |
| -------------------------------------- | ---------------------------------------- |
| `~/.config/zellij/plugins/zj-barename.wasm` | 当前顶栏产物（已改暗蓝）                 |
| `~/.config/zellij/plugins/zj-barename.wasm.bak-red` | 改色前备份（红）               |
| `~/.config/zellij/install-pomodoro.sh` | 一键安装；第 5 节时区、**5b 节改色**         |
| `~/.config/zellij/INSTALL-POMODORO.md` | 番茄钟总文档；补丁 B/D                   |
| `~/.config/zellij/layouts/default.kdl` | 顶栏加载 `zj-barename.wasm` 的布局         |
| 源码仓 `bihari123/zj-barename` `src/tab.rs` | `INACTIVE_TAB_BG` 定义             |
