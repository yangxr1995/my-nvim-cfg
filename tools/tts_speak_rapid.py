#!/usr/bin/env python3
"""RapidTTS backends (kokoro / moss_nano) for nvim tts.lua, local & offline.

Requires the venv where rapidtts is installed:
    /root/test/tts/.venv/bin/python tts_speak_rapid.py [kokoro|moss] [voice]
    echo "text" | tts_speak_rapid.py kokoro        # synthesize, play via ffplay, save last wav
    tts_speak_rapid.py replay                      # replay last saved wav
"""
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

CACHE_DIR = Path.home() / ".cache/nvim/tts"
LAST_WAV = CACHE_DIR / "last_audio.wav"

BACKENDS = {
    "kokoro": (TTSModel.KOKORO_ONNX, "zm_009"),
    "moss": (TTSModel.MOSS_NANO_ONNX, "Junhao"),
}


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
    play(LAST_WAV)


def replay() -> None:
    if not LAST_WAV.exists():
        sys.stderr.write(f"no audio to replay: {LAST_WAV}\n")
        sys.exit(1)
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
