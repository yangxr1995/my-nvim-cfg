#!/usr/bin/env python3
"""Piper TTS backend for nvim tts.lua (local, offline).

Usage:
    echo "text" | python3 tts_speak.py [zh|en]   # synthesize, stream-play, save last wav
    python3 tts_speak.py replay                  # replay last saved wav
"""
import sys
import wave
from pathlib import Path

from piper import PiperVoice
from piper.audio_playback import AudioPlayer

VOICES_DIR = Path.home() / ".local/share/nvim/tts-nvim/piper_voices"
CACHE_DIR = Path.home() / ".cache/nvim/tts"
MODELS = {
    "zh": VOICES_DIR / "zh_CN-huayan-medium.onnx",
    "en": VOICES_DIR / "en_US-lessac-medium.onnx",
}
LAST_WAV = CACHE_DIR / "last_audio.wav"

_voices = {}


def get_voice(lang: str) -> PiperVoice:
    if lang not in _voices:
        # download_dir lets the zh model resolve its g2pW pinyin resources offline
        _voices[lang] = PiperVoice.load(MODELS[lang], download_dir=VOICES_DIR)
    return _voices[lang]


def speak(text: str, lang: str) -> None:
    voice = get_voice(lang)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with wave.open(str(LAST_WAV), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(voice.config.sample_rate)
        with AudioPlayer(voice.config.sample_rate) as player:
            for chunk in voice.synthesize(text):
                frames = chunk.audio_int16_bytes
                player.play(frames)
                # persist while streaming so replay() can reuse it
                wav_file.writeframes(frames)


def replay() -> None:
    with wave.open(str(LAST_WAV), "rb") as wav_file:
        with AudioPlayer(wav_file.getframerate()) as player:
            while True:
                frames = wav_file.readframes(4096)
                if not frames:
                    break
                player.play(frames)


def main() -> None:
    arg = sys.argv[1] if len(sys.argv) > 1 else "zh"
    if arg == "replay":
        replay()
    else:
        lang = arg if arg in MODELS else "zh"
        text = sys.stdin.read().strip()
        if text:
            speak(text, lang)


if __name__ == "__main__":
    main()
