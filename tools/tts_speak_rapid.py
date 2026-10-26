#!/usr/bin/env python3
"""RapidTTS backends (kokoro / moss_nano) for nvim tts.lua, local & offline.

Requires the venv where rapidtts is installed:
    /root/test/tts/.venv/bin/python tts_speak_rapid.py [kokoro|moss] [voice]
    echo "text" | tts_speak_rapid.py kokoro        # synthesize, play via ffplay, save last wav
    tts_speak_rapid.py replay                      # replay last saved wav
"""
import logging
import os
import subprocess
import sys
import wave
from pathlib import Path

try:
    from rapidtts import RapidTTS, SynthesisRequest, TTSModel
except ImportError:
    sys.stderr.write(
        "rapidtts not installed. Run inside /root/test/tts:\n"
        "  .venv/bin/pip install \"rapidtts[kokoro]\" \"rapidtts[moss_nano]\"\n"
    )
    sys.exit(1)

import logging

# rapidtts 与 jieba 会把 INFO 日志写进 stderr；nvim 端把 stderr 当错误诊断展示，
# 降噪到 WARNING，让 stderr 只承载真正的错误信息。
# 注意：jieba 在 import 时会自行 setLevel(DEBUG)，必须 import 后再调它的 setLogLevel
logging.getLogger("RapidTTS").setLevel(logging.WARNING)
import jieba

jieba.setLogLevel(logging.WARNING)

CACHE_DIR = Path.home() / ".cache/nvim/tts"
LAST_WAV = CACHE_DIR / "last_audio.wav"
DENOISED_MARK = CACHE_DIR / "last_audio.denoised"

# 默认开启降噪；TTS_DENOISE=0 可关闭。
# 幂等：标记文件存在且不旧于音频时跳过，避免对已降噪的音频重复处理
DENOISE_FILTERS = "highpass=f=60,afftdn=nr=12"


def denoise(wav: Path) -> None:
    if os.getenv("TTS_DENOISE") == "0":
        return
    if (
        DENOISED_MARK.exists()
        and wav.exists()
        and DENOISED_MARK.stat().st_mtime >= wav.stat().st_mtime
    ):
        return
    tmp = wav.with_name(wav.stem + ".denoising.wav")
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-af", DENOISE_FILTERS, str(tmp)],
        check=True,
    )
    tmp.replace(wav)
    DENOISED_MARK.write_text("", encoding="utf-8")

BACKENDS = {
    "kokoro": (TTSModel.KOKORO_ONNX, "zm_009"),
    "moss": (TTSModel.MOSS_NANO_ONNX, "Junhao"),
}


def say(msg: str) -> None:
    """阶段提示输出到 stdout, nvim 端捕获显示 (flush 保证立即送达)"""
    print(f"[tts] {msg}", flush=True)


def play(wav: Path) -> None:
    subprocess.run(
        ["ffplay", "-nodisp", "-autoexit", "-loglevel", "error", str(wav)],
        check=False,
    )


def speak(text: str, backend: str, voice: str | None) -> None:
    model, default_voice = BACKENDS[backend]
    tts = RapidTTS(model=model)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    resp = tts.synthesize(SynthesisRequest(text=text, voice=voice or default_voice))
    resp.save(str(LAST_WAV))
    denoise(LAST_WAV)
    say("正在播放...")
    play(LAST_WAV)


def replay() -> None:
    if not LAST_WAV.exists():
        sys.stderr.write(f"no audio to replay: {LAST_WAV}\n")
        sys.exit(1)
    say("正在播放...")
    with wave.open(str(LAST_WAV), "rb") as wav_file:
        print(f"replay: {wav_file.getnframes() / wav_file.getframerate():.1f}s")
    play(LAST_WAV)


def main() -> None:
    arg = sys.argv[1] if len(sys.argv) > 1 else "kokoro"
    if arg == "replay":
        replay()
        return
    if arg not in BACKENDS:
        sys.stderr.write(f"unknown backend: {arg} (expected: {', '.join(BACKENDS)})\n")
        sys.exit(1)
    voice = sys.argv[2] if len(sys.argv) > 2 else None
    text = sys.stdin.read().strip()
    if text:
        speak(text, arg, voice)


if __name__ == "__main__":
    main()
