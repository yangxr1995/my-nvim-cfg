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

# ---------- 4c. 补丁: zj-pomodoro 跨 session 状态持久化 ----------
# 根因: zellij 0.40+ 每次客户端 attach 都会重建插件实例(load() 重跑)，
#       内存计时随 session 切换丢失；且插件广播不跨 session。
# 方案: 计时真值落盘 /cache（zellij 为插件 URL 无条件挂载的稳定目录），
#       各 session 实例通过 owner_nonce+heartbeat 选主对账，支持失联接管。
# 依赖: 4a 的 RunCommands 锚点已应用（本段锚点含其产出文本）。
# 注意: 不要给插件新增 permissions.kdl 缓存外的权限（如 FullHdAccess）——
#       后台插件授权框弹不出来（zellij#4982），新权限会被整体拒绝并连累已授权项。
log "补丁: zj-pomodoro 跨 session 状态持久化（状态文件+选主+对账循环）"
python3 - "$BUILD_DIR/zj-pomodoro/src/main.rs" <<'PYEOF3'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
if "zj-pomodoro.state" in src:
    print("  跨session补丁已应用，跳过")
    sys.exit(0)

B1 = '''// ===================== 跨 session 状态持久化 =====================
// zellij 0.40+ 在每次客户端 attach 时都会为所有插件创建全新 WASM 实例并重跑
// load()，内存状态随 session 切换/重建丢失。因此把计时真值落盘：
// /cache 是 zellij 为每个插件 URL 挂载的稳定目录
// （~/.cache/zellij/<url>/plugin_cache），同插件所有实例跨 session 共享。
//
// 文件格式: status|end|streak|work_mins|break_mins|owner_nonce|heartbeat
// - owner_nonce 标记当前"控制实例"；heartbeat 是它最近的活跃时间
// - 其余实例只读并对账（follower）；owner 心跳停跳超过 STALE_SECS 后，
//   最先发现的新实例可原子换写 owner_nonce 完成接管（claim）
// - 所有写入都是 临时文件 + rename 原子替换，最后写者胜出
const STATE_PATH: &str = "/cache/zj-pomodoro.state";
const STATE_PATH_FALLBACK: &str = "/tmp/zj-pomodoro.state";
const TICK_SECS: f64 = 10.0;
const STALE_SECS: u64 = 25;

fn now_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

/// 文件里的状态比内存 Status 多一档 Done（边界已报告、等待应答），
/// 单独建枚举，避免侵入上游 Status。
#[derive(Clone, Copy, PartialEq)]
enum FileStatus {
    Off,
    Run(Status),
    Done,
}

#[derive(Clone, Copy)]
struct FileState {
    status: FileStatus,
    end: u64,
    streak: u32,
    work_mins: u64,
    break_mins: u64,
    nonce: u64,
    hb: u64,
}

impl FileState {
    fn parse(s: &str) -> Option<FileState> {
        let p: Vec<&str> = s.trim().split('|').collect();
        if p.len() != 7 {
            return None;
        }
        let status = match p[0] {
            "off" => FileStatus::Off,
            "done" => FileStatus::Done,
            "work" => FileStatus::Run(Status::Work),
            "break" => FileStatus::Run(Status::Break),
            _ => return None,
        };
        Some(FileState {
            status,
            end: p[1].parse().ok()?,
            streak: p[2].parse().ok()?,
            work_mins: p[3].parse().ok()?,
            break_mins: p[4].parse().ok()?,
            nonce: p[5].parse().ok()?,
            hb: p[6].parse().ok()?,
        })
    }

    fn serialize(&self) -> String {
        let s = match self.status {
            FileStatus::Off => "off",
            FileStatus::Done => "done",
            FileStatus::Run(Status::Work) => "work",
            FileStatus::Run(Status::Break) => "break",
            // 按构造不会出现（Off 走 FileStatus::Off），兜底映射保持文件合法
            FileStatus::Run(Status::Off) => "off",
        };
        format!(
            "{}|{}|{}|{}|{}|{}|{}",
            s, self.end, self.streak, self.work_mins, self.break_mins, self.nonce, self.hb
        )
    }
}

fn read_file_state() -> Option<FileState> {
    for path in [STATE_PATH, STATE_PATH_FALLBACK] {
        if let Ok(s) = std::fs::read_to_string(path) {
            if let Some(fs) = FileState::parse(&s) {
                return Some(fs);
            }
        }
    }
    None
}

fn write_file_state(fs: &FileState) {
    let body = fs.serialize();
    for path in [STATE_PATH, STATE_PATH_FALLBACK] {
        let tmp = format!("{}.tmp", path);
        if std::fs::write(&tmp, &body).is_ok() && std::fs::rename(&tmp, path).is_ok() {
            return;
        }
    }
}'''
B2 = '''    // ===================== 跨 session 对账 =====================

    fn file_snapshot(&self, nonce: u64, hb: u64) -> FileState {
        FileState {
            status: if self.status == Status::Off {
                FileStatus::Off
            } else {
                FileStatus::Run(self.status)
            },
            end: self.end,
            streak: self.streak,
            work_mins: self.work_mins,
            break_mins: self.break_mins,
            nonce,
            hb,
        }
    }

    /// 用户动作（启动/边界应答）后的落盘：本实例成为全局控制者。
    fn persist_running(&mut self) {
        self.controller = true;
        write_file_state(&self.file_snapshot(self.nonce, now_secs()));
    }

    /// 用户停止/取消后的落盘：全局回到空闲，控制权清零。
    fn persist_off(&mut self) {
        self.controller = false;
        write_file_state(&FileState {
            status: FileStatus::Off,
            end: 0,
            streak: 0,
            work_mins: self.work_mins,
            break_mins: self.break_mins,
            nonce: 0,
            hb: 0,
        });
    }

    /// 跟随全局状态（只改展示相关字段，不抢控制权）。
    /// broadcast=false 用于 load 阶段：权限尚未就绪时广播会被拒（zellij 异步授权），
    /// 状态先入内存，首个 tick 会再广播补上显示。
    fn adopt(&mut self, fs: &FileState, broadcast: bool) {
        match fs.status {
            FileStatus::Run(s) => {
                self.status = s;
                self.end = fs.end;
                self.streak = fs.streak;
                self.pending_boundary = None;
                self.work_mins = fs.work_mins;
                self.break_mins = fs.break_mins;
                self.hide_pane_if_idle();
                if broadcast {
                    self.broadcast_state();
                }
            },
            FileStatus::Off => {
                let had_state = self.status != Status::Off || self.pending_boundary.is_some();
                self.status = Status::Off;
                self.end = 0;
                self.streak = 0;
                self.pending_boundary = None;
                if had_state {
                    self.hide_pane_if_idle();
                    if broadcast {
                        self.broadcast_state();
                    }
                }
            },
            FileStatus::Done => {
                // 边界已被某个实例报告。若是自己报的（菜单还挂着且 end 吻合），
                // 继续等应答；否则只是别人的边界，展示层保持不动。
                if !(self.pending_boundary.is_some() && self.end == fs.end) {
                    self.controller = false;
                    self.pending_boundary = None;
                }
            },
        }
    }

    /// 接管全局计时（原 owner 失联）。原子换写 owner_nonce，最后写者胜出；
    /// 写后回读校验归属，抢输的实例自动降级为 follower。
    fn claim(&mut self, fs: &FileState) -> bool {
        let mut next = *fs;
        next.nonce = self.nonce;
        next.hb = now_secs();
        write_file_state(&next);
        matches!(read_file_state(), Some(cur) if cur.nonce == self.nonce)
    }

    /// 到期边界：系统通知 + 标记 done + 弹出应答菜单。
    fn fire_boundary(&mut self) {
        run_command(
            &["notify-send", "Pomodoro", "番茄钟计时结束"],
            BTreeMap::new(),
        );
        self.pending_boundary = Some(self.status);
        write_file_state(&FileState {
            status: FileStatus::Done,
            end: self.end,
            streak: self.streak,
            work_mins: self.work_mins,
            break_mins: self.break_mins,
            nonce: 0,
            hb: 0,
        });
        self.surface_menu();
    }

    fn hide_pane_if_idle(&mut self) {
        if self.setup.is_none() && self.pending_boundary.is_none() {
            self.hide_pane();
        }
    }

    /// 操作（Alt z）前先对账，避免刚重建的实例拿过期内存值做判断。
    fn refresh_from_file(&mut self, quiet: bool) {
        if let Some(fs) = read_file_state() {
            if fs.nonce != self.nonce {
                self.adopt(&fs, !quiet);
            }
        }
    }

    /// 周期对账：所有实例每 TICK 唤醒一次。控制者写心跳并负责到期边界；
    /// 其他实例跟随全局文件；全局 owner 心跳失联后由最先发现者接管。
    fn tick(&mut self) {
        set_timeout(TICK_SECS);
        let Some(fs) = read_file_state() else {
            // 文件缺失/损坏：控制者重写快照，否则本地退回空闲
            if self.controller && (self.status != Status::Off || self.pending_boundary.is_some()) {
                write_file_state(&self.file_snapshot(self.nonce, now_secs()));
            } else if self.status != Status::Off || self.pending_boundary.is_some() {
                self.status = Status::Off;
                self.end = 0;
                self.streak = 0;
                self.pending_boundary = None;
                self.controller = false;
                self.hide_pane_if_idle();
                self.broadcast_state();
            }
            return;
        };
        let now = now_secs();
        match fs.status {
            FileStatus::Run(_) if fs.nonce == self.nonce => {
                self.controller = true;
                write_file_state(&self.file_snapshot(self.nonce, now));
                if self.pending_boundary.is_some() {
                    // 未应答边界：菜单被 Esc 收起后由下一轮 tick 重新弹出
                    if !self.pane_visible {
                        self.show_pane();
                    }
                } else if self.status != Status::Off && now >= self.end {
                    self.fire_boundary();
                }
            },
            FileStatus::Run(_) => {
                if now.saturating_sub(fs.hb) > STALE_SECS && self.claim(&fs) {
                    self.controller = true;
                    self.status = match fs.status {
                        FileStatus::Run(s) => s,
                        _ => Status::Off,
                    };
                    self.end = fs.end;
                    self.streak = fs.streak;
                    self.work_mins = fs.work_mins;
                    self.break_mins = fs.break_mins;
                    self.pending_boundary = None;
                    self.broadcast_state();
                    if now >= self.end {
                        self.fire_boundary();
                    }
                } else {
                    self.controller = false;
                    self.adopt(&fs, true);
                }
            },
            FileStatus::Done => self.adopt(&fs, true),
            FileStatus::Off => {
                self.controller = false;
                self.adopt(&fs, true);
            },
        }
    }
}'''

def rep(s, old, new, tag):
    if old not in s:
        print("ERROR: 锚点失配: %s（上游源码可能已变化，需人工核对）" % tag, file=sys.stderr)
        sys.exit(1)
    return s.replace(old, new, 1)

# 1) 持久化基础设施（常量/格式/原子读写），插在 register_plugin! 之后
src = rep(src, "register_plugin!(State);\n",
    "register_plugin!(State);\n\n" + B1 + "\n", "持久化基础设施块")

# 2) State 字段
src = rep(src,
    "    pane_visible: bool,\n}",
    "    pane_visible: bool,\n"
    "    /// 本实例身份（load 时生成），用作状态文件的 owner_nonce。\n"
    "    nonce: u64,\n"
    "    /// 是否为当前全局计时的控制实例（负责心跳、到期通知与边界菜单）。\n"
    "    controller: bool,\n}",
    "State 字段")

# 3) Default
src = rep(src,
    "            pane_visible: false,\n        }\n    }\n}",
    "            pane_visible: false,\n            nonce: 0,\n            controller: false,\n        }\n    }\n}",
    "Default 初始化")

# 4) start_session 落盘
src = rep(src,
    "        set_timeout((mins * 60) as f64);\n        self.broadcast_state();\n",
    "        set_timeout((mins * 60) as f64);\n        self.broadcast_state();\n        self.persist_running();\n",
    "start_session 落盘")

# 5) stop 落盘
src = rep(src,
    "        self.hide_pane();\n        self.broadcast_state();\n    }\n",
    "        self.hide_pane();\n        self.broadcast_state();\n        self.persist_off();\n    }\n",
    "stop 落盘")

# 6) toggle 先对账
src = rep(src,
    "    fn toggle(&mut self) {\n        if self.status",
    "    fn toggle(&mut self) {\n        self.refresh_from_file(false);\n        if self.status",
    "toggle 对账")

# 7) load() 末尾: 身份初始化 + 静默对账 + 启动对账循环
src = rep(src,
    "            EventType::PermissionRequestResult,\n        ]);\n",
    "            EventType::PermissionRequestResult,\n        ]);\n"
    "        // zellij 会为 attach 上来的客户端重建实例（内存归零），\n"
    "        // 这里认领身份并静默对账全局状态（load 期广播会被拒），\n"
    "        // 首个 tick 会把状态广播给顶栏，恢复倒计时显示。\n"
    "        self.nonce = now_millis();\n"
    "        self.refresh_from_file(true);\n"
    "        set_timeout(TICK_SECS);\n",
    "load() 初始化")

# 8) Timer 处理臂整体替换为对账循环（依赖 4b 已插入 notify-send 行）
src = rep(src,
    "            Event::Timer(_) => {\n"
    "                if self.pending_boundary.is_some() {\n"
    "                    // Unanswered boundary: (re-)show the menu and keep re-arming.\n"
    "                    self.surface_menu();\n"
    "                } else if self.status != Status::Off && now_secs() >= self.end {\n"
    "                run_command(&[\"notify-send\", \"Pomodoro\", \"番茄钟计时结束\"], BTreeMap::new());\n"
    "                    self.pending_boundary = Some(self.status);\n"
    "                    self.surface_menu();\n"
    "                }\n"
    "                // Any other firing is a stale timer from a session that was\n"
    "                // stopped or restarted — ignore it.\n"
    "                true\n"
    "            },",
    "            Event::Timer(_) => {\n                self.tick();\n                true\n            },",
    "Timer 臂替换")

# 9) 对账方法块，插在第一个 impl State 末尾
src = rep(src,
    "            _ => false,\n        }\n    }\n}\n\nimpl ZellijPlugin for State {",
    "            _ => false,\n        }\n    }\n\n" + B2 + "\n\nimpl ZellijPlugin for State {",
    "对账方法块")

# 10) 修正上游过时注释（"不落盘"的声明在打补丁后不再成立）
src = src.replace(
    "        // Notably NOT FullHdAccess \u2014 nothing is persisted to disk.\n",
    "        // \u6ce8\u610f\uff1a\u72b6\u6001\u6587\u4ef6\u4f9d\u8d56 zellij \u5bf9\u63d2\u4ef6\u65e0\u6761\u4ef6\u6302\u8f7d\u7684 /cache \u76ee\u5f55\uff08plugin_loader.rs\n"
    "        // create_wasi_ctx\uff09\uff0c\u65e0\u9700\u4efb\u4f55\u6587\u4ef6\u6743\u9650\u3002\u5343\u4e07\u4e0d\u8981\u5728\u8fd9\u91cc\u65b0\u589e\u7f13\u5b58\u4e2d\u6ca1\u6709\u7684\u6743\u9650\u2014\u2014\n"
    "        // \u540e\u53f0\u63d2\u4ef6\u7684\u6388\u6743\u6846\u5f39\u4e0d\u51fa\u6765\uff08zellij#4982\uff09\uff0c\u65b0\u6743\u9650\u4f1a\u88ab\u6574\u4f53\u62d2\u7edd\u5e76\u8fde\u7d2f\u5df2\u6388\u6743\u9879\u3002\n",
    1)

open(path, "w", encoding="utf-8").write(src)
print("  补丁已应用: 状态文件 /cache + owner 选举 + 10s 对账")
PYEOF3

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

# ---------- 5b. 补丁: zj-barename 未选中 tab 背景 红 -> 暗蓝 ----------
# 上游硬编码 INACTIVE_TAB_BG #d03333（主题无法覆盖），改为暗蓝 #1a3380
log "补丁: zj-barename 未选中 tab 背景红 #d03333 -> 暗蓝 #1a3380"
BARENAME_TAB_SRC="$BUILD_DIR/zj-barename/src/tab.rs"
if grep -q "0x1a, 0x33, 0x80" "$BARENAME_TAB_SRC"; then
    log "  已打过补丁，跳过"
else
    # 兼容上游红、以及先前亮蓝 #3366d0 两种中间态
    sed -i \
        -e 's/PaletteColor::Rgb((0xd0, 0x33, 0x33))/PaletteColor::Rgb((0x1a, 0x33, 0x80))/' \
        -e 's/PaletteColor::Rgb((0x33, 0x66, 0xd0))/PaletteColor::Rgb((0x1a, 0x33, 0x80))/' \
        "$BARENAME_TAB_SRC"
    grep -q "0x1a, 0x33, 0x80" "$BARENAME_TAB_SRC" || die "barename 改色补丁失败（锚点 Rgb(...) 未找到）"
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
