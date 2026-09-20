#!/usr/bin/env bash
# ============================================================================
# zellij 番茄钟 + 实时时钟 + 定时闹钟 一键安装脚本
#
# 适用于 zellij 0.44.x（在 0.44.3 上端到端验证）。其他版本见同目录
# INSTALL-POMODORO.md 的"兼容性说明"。
#
# 功能:
#   - 番茄钟 zj-pomodoro（Alt z 启动，倒计时显示在顶栏，到期 notify-send 通知）
#   - 顶栏时钟 zj-barename（默认时区补丁为 +08:00）
#   - at 定时闹钟（apt 系统）
#
# 脚本幂等：可重复执行。已完成的步骤自动跳过。
# 完成后需开启新的 zellij 会话才能生效。
# ============================================================================
set -euo pipefail

ZELLIJ_CFG_DIR="${ZELLIJ_CFG_DIR:-$HOME/.config/zellij}"
PLUGIN_DIR="$ZELLIJ_CFG_DIR/plugins"
LAYOUT_DIR="$ZELLIJ_CFG_DIR/layouts"
BUILD_DIR="${BUILD_DIR:-/tmp/zellij-pomodoro-build}"
POMO_REPO="https://github.com/bihari123/zj-pomodoro"
BARENAME_REPO="https://github.com/bihari123/zj-barename"

log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------- 0. 前置检查 ----------
command -v zellij >/dev/null || die "未找到 zellij"
command -v cargo  >/dev/null || die "未找到 cargo（安装 rust: https://rustup.rs）"
command -v rustup >/dev/null || die "未找到 rustup（wasm 编译 target 需要）"
command -v python3 >/dev/null || die "未找到 python3（补丁脚本需要）"
command -v notify-send >/dev/null || warn "未找到 notify-send，番茄钟到期通知将静默失败（需通知守护进程 dunst/mako）"

ZELLIJ_VER="$(zellij --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
MAJOR_MINOR="${ZELLIJ_VER%.*}"
if [[ "$MAJOR_MINOR" != "0.44" ]]; then
    warn "当前 zellij $ZELLIJ_VER 非 0.44.x。0.40-0.44 大概率可用；0.45+ 需复核补丁锚点与布局行为（见 INSTALL-POMODORO.md）"
fi

# ---------- 1. 可选依赖: at（定时闹钟） ----------
if ! command -v at >/dev/null; then
    if command -v apt-get >/dev/null; then
        log "安装 at（定时闹钟）"
        DEBIAN_FRONTEND=noninteractive apt-get install -y at >/dev/null 2>&1 \
            || warn "at 安装失败，定时闹钟不可用（其余功能不受影响）"
    else
        warn "非 apt 系统: 请手动安装 at 以启用定时闹钟"
    fi
fi

# ---------- 2. wasm 编译 target ----------
log "确保 rustup target: wasm32-wasip1"
rustup target add wasm32-wasip1 >/dev/null 2>&1 \
    || die "rustup target add wasm32-wasip1 失败（多为网络问题，请重试）"

mkdir -p "$PLUGIN_DIR" "$LAYOUT_DIR" "$BUILD_DIR"

# ---------- 3. 克隆源码 ----------
# 网络不佳时可设置镜像前缀，如: GIT_MIRROR="https://ghproxy.net/https://github.com" bash install-pomodoro.sh
clone() { # $1=repo_url  $2=dest_dir
    if [ -d "$2/.git" ]; then
        log "源码已存在: $2（跳过克隆）"
        return 0
    fi
    local attempt
    for attempt in 1 2 3; do
        log "克隆 $1（第 $attempt 次尝试）"
        if git clone --depth 1 "$1" "$2" 2>/dev/null; then
            return 0
        fi
        rm -rf "$2"
        sleep 3
    done
    if [ -n "${GIT_MIRROR:-}" ]; then
        log "直连失败，使用镜像: $GIT_MIRROR"
        git clone --depth 1 "$GIT_MIRROR/$1" "$2" && return 0
        rm -rf "$2"
    fi
    die "克隆失败: $1（重试仍失败。可设置镜像后重跑，例: GIT_MIRROR=\"https://ghproxy.net/https://github.com\" bash $0）"
}
clone "$POMO_REPO"    "$BUILD_DIR/zj-pomodoro"
clone "$BARENAME_REPO" "$BUILD_DIR/zj-barename"

# ---------- 4. 补丁: zj-pomodoro 到期通知 ----------
# 4a. request_permission 权限数组追加 RunCommands（exec 通知的权限门槛）
# 4b. Event::Timer 到期分支首行插入 run_command(notify-send)
log "补丁: zj-pomodoro 到期 notify-send 通知"
python3 - "$BUILD_DIR/zj-pomodoro/src/main.rs" <<'PYEOF'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
if "PermissionType::RunCommands" in src and "run_command(&[\"notify-send\"" in src:
    print("  已打过补丁，跳过")
    sys.exit(0)

anchor = "PermissionType::MessageAndLaunchOtherPlugins,"
if anchor not in src:
    print("ERROR: 权限数组锚点未找到（上游源码可能已变化，需人工核对）", file=sys.stderr)
    sys.exit(1)
src = src.replace(anchor, anchor + "\n            PermissionType::RunCommands,", 1)

anchor2 = "} else if self.status != Status::Off && now_secs() >= self.end {"
call = '\n                run_command(&["notify-send", "Pomodoro", "番茄钟计时结束"], BTreeMap::new());'
if anchor2 not in src:
    print("ERROR: 到期分支锚点未找到（上游源码可能已变化，需人工核对）", file=sys.stderr)
    sys.exit(1)
src = src.replace(anchor2, anchor2 + call, 1)

open(path, "w", encoding="utf-8").write(src)
print("  补丁已应用: RunCommands 权限 + 到期分支 notify-send")
PYEOF

# ---------- 5. 补丁: zj-barename 时钟默认时区 IST -> CST(+08:00) ----------
# 上游默认 +05:30（作者本地时区），无 tz 数据库，为固定秒数偏移
log "补丁: zj-barename 时钟默认时区 +05:30 -> +08:00"
BARENAME_SRC="$BUILD_DIR/zj-barename/src/main.rs"
if grep -q "unwrap_or(28800)" "$BARENAME_SRC"; then
    log "  已打过补丁，跳过"
else
    sed -i 's/\.unwrap_or(19800)/.unwrap_or(28800)/' "$BARENAME_SRC"
    grep -q "unwrap_or(28800)" "$BARENAME_SRC" || die "barename 时区补丁失败（锚点 unwrap_or(19800) 未找到）"
    log "  补丁已应用"
fi

# ---------- 6. 编译 ----------
build_wasm() { # $1=src_dir
    log "编译 $(basename "$1")（约 1-2 分钟）" >&2
    (cd "$1" && cargo build --release --target wasm32-wasip1 >/dev/null 2>&1) \
        || die "编译失败: $1（重跑查看完整报错: cd $1 && cargo build --release --target wasm32-wasip1）"
    find "$1/target/wasm32-wasip1/release" -maxdepth 1 -name "*.wasm" | head -1
}
POMO_WASM="$(build_wasm "$BUILD_DIR/zj-pomodoro")"
BARE_WASM="$(build_wasm "$BUILD_DIR/zj-barename")"

cp "$POMO_WASM"    "$PLUGIN_DIR/zj-pomodoro.wasm"
cp "$BARE_WASM"    "$PLUGIN_DIR/zj-barename.wasm"
log "已安装 zj-pomodoro.wasm 与 zj-barename.wasm"

# ---------- 7. wasm ABI 校验（wasm 二进制中 module/field 名为独立字符串，按 field 名判别） ----------
log "校验 wasm 插件 ABI"
python3 - "$PLUGIN_DIR/zj-pomodoro.wasm" "$PLUGIN_DIR/zj-barename.wasm" <<'PYEOF'
import sys
ok = True
for p in sys.argv[1:]:
    data = open(p, "rb").read()
    has_new = b"host_run_plugin_command" in data
    has_old = b"host_subscribe" in data
    if has_old:
        print(f"ERROR: {p} 含旧 API 导入 host_subscribe，无法在 zellij 0.40+ 加载", file=sys.stderr)
        ok = False
    elif has_new:
        print(f"  OK: {p}（新插件 API）")
    else:
        print(f"WARN: {p} 未检测到 zellij 导入特征（结构异常？）")
sys.exit(0 if ok else 1)
PYEOF

# ---------- 8. 布局文件 ----------
log "写入布局 $LAYOUT_DIR/default.kdl"
cat > "$LAYOUT_DIR/default.kdl" <<'EOF'
// 默认布局：顶部 zj-barename（tab 名 + 时钟 + 番茄钟倒计时），底部官方 status-bar
// 注意：zellij 0.44.x 会话首 tab 存在 plugin 配置丢失 bug，
//       因此一切 bar 插件不得依赖 layout 内联配置（时钟时区已在源码中修正）
layout {
    pane size=1 borderless=true {
        plugin location="file:$HOME/.config/zellij/plugins/zj-barename.wasm"
    }
    pane
    pane size=1 borderless=true {
        plugin location="status-bar"
    }
}
EOF
# heredoc 不展开 $HOME，手动替换
sed -i "s|\$HOME|$HOME|g" "$LAYOUT_DIR/default.kdl"

# ---------- 9. config.kdl 修改（幂等 + 备份） ----------
CONFIG="$ZELLIJ_CFG_DIR/config.kdl"
CONFIG_NEED_MANUAL=0
if [ -f "$CONFIG" ]; then
    cp -n "$CONFIG" "$CONFIG.bak-pomodoro" 2>/dev/null || true
    log "修改 config.kdl（备份: $CONFIG.bak-pomodoro）"

    python3 - "$CONFIG" "$HOME" <<'PYEOF'
import sys
path, home = sys.argv[1], sys.argv[2]
src = open(path, encoding="utf-8").read()

# 9a. load_plugins 追加 zj-pomodoro（后台常驻，计时核心）
if "zj-pomodoro.wasm" not in src:
    if "load_plugins {" in src:
        entry = ('    "file:%s/.config/zellij/plugins/zj-pomodoro.wasm" {\n'
                 '        work_mins "25"\n'
                 '        break_mins "5"\n'
                 '    }\n') % home
        src = src.replace("load_plugins {\n", "load_plugins {\n" + entry, 1)
        print("  已添加: load_plugins -> zj-pomodoro")
    else:
        src += ('\nload_plugins {\n'
                '    "file:%s/.config/zellij/plugins/zj-pomodoro.wasm" {\n'
                '        work_mins "25"\n'
                '        break_mins "5"\n'
                '    }\n}\n') % home
        print("  已追加: load_plugins 段 -> zj-pomodoro")

# 9b. 快捷键 Alt z -> 番茄钟开关（广播 MessagePlugin）
if "pomodoro_toggle" not in src:
    bind = ('        bind "Alt z" {\n'
            '            MessagePlugin {\n'
            '                name "pomodoro_toggle"\n'
            '            }\n'
            '        }\n')
    anchor = 'bind "Alt x" { Quit; }'
    if anchor in src:
        src = src.replace(anchor, bind + "        " + anchor, 1)
        print("  已添加: Alt z -> pomodoro_toggle")
    else:
        src += ('\nkeybinds {\n'
                '    shared_except "locked" {\n' + bind + '    }\n}\n')
        print("  已追加: 独立 keybinds 段 -> Alt z pomodoro_toggle（未找到 Alt x 锚点，追加于文件尾，如有冲突请手动合并）")

open(path, "w", encoding="utf-8").write(src)
PYEOF
else
    warn "config.kdl 不存在（zellij 首次启动会自动生成）。生成后重跑本脚本即可完成快捷键与后台加载配置"
    CONFIG_NEED_MANUAL=1
fi

# ---------- 10. 预写权限缓存（避免首次加载弹确认框） ----------
PERM="$HOME/.cache/zellij/permissions.kdl"
mkdir -p "$(dirname "$PERM")"
touch "$PERM"
if ! grep -q "zj-pomodoro.wasm" "$PERM"; then
    cat >> "$PERM" <<EOF
"$HOME/.config/zellij/plugins/zj-pomodoro.wasm" {
    RunCommands
    ChangeApplicationState
    MessageAndLaunchOtherPlugins
}
EOF
fi
if ! grep -q "zj-barename.wasm" "$PERM"; then
    cat >> "$PERM" <<EOF
"$HOME/.config/zellij/plugins/zj-barename.wasm" {
    ChangeApplicationState
    ReadApplicationState
}
EOF
fi
log "权限缓存已就绪: $PERM"

# ---------- 11. 摘要 ----------
PLUGIN_MISSING=0
for f in zj-pomodoro.wasm zj-barename.wasm; do
    [ -s "$PLUGIN_DIR/$f" ] || { warn "缺失: $PLUGIN_DIR/$f"; PLUGIN_MISSING=1; }
done
[ "$PLUGIN_MISSING" -eq 0 ] || die "插件文件缺失，安装未完成"

log "安装完成！使用说明："
echo "  1. 开启新的 zellij 会话生效（旧会话不受影响）"
echo "  2. Alt z            : 番茄钟 启动/停止菜单（默认 25 分钟工作 + 5 分钟休息，Enter 确认）"
echo "  3. 顶栏             : tab 名 + 实时时钟(+08:00) + 倒计时（番茄钟运行时显示 W mm:ss）"
echo "  4. 到期通知         : notify-send 系统通知 + 界面菜单（b 休息 / w 继续 / c 取消）"
echo "  5. 定时闹钟         : echo 'notify-send \"闹钟\" \"时间到\"' | at 15:00"
[ "$CONFIG_NEED_MANUAL" -eq 1 ] && echo "  !! config.kdl 待生成：zellij 首次启动后重跑本脚本以完成快捷键配置"
exit 0
