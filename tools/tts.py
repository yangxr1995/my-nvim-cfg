#!/usr/bin/python3

import argparse
import requests
import json
import sys
import os

# Minimaxi TTS API配置
API_URL = "https://api.minimaxi.com/v1/t2a_v2"
DEFAULT_MODEL = "speech-2.6-turbo"
DEFAULT_VOICE_ID = "male-qn-qingse"

def hex_to_binary(hex_string):
    """将十六进制字符串转换为二进制数据"""
    try:
        return bytes.fromhex(hex_string)
    except ValueError as e:
        raise ValueError(f"无效的十六进制字符串: {e}")

def tts_synthesis(api_key, text, output_file, model=DEFAULT_MODEL, voice_id=DEFAULT_VOICE_ID, speed=1.0):
    """
    使用Minimaxi API进行语音合成

    Args:
        api_key: API密钥
        text: 要合成的文本
        output_file: 输出文件路径
        model: 模型版本
        voice_id: 音色ID
        speed: 语音速度 (0.5-2.0)
    """
    
    # 构建请求头
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    # 构建请求体
    payload = {
        "model": model,
        "text": text,
        "stream": False,
        "voice_setting": {
            "voice_id": voice_id,
            "speed": speed,
            "vol": 1.0,
            "pitch": 0
        },
        "audio_setting": {
            "sample_rate": 32000,
            "bitrate": 128000,
            "format": "mp3",
            "channel": 1
        },
        "output_format": "hex"
    }
    
    try:
        # 发送POST请求
        response = requests.post(API_URL, headers=headers, json=payload)
        response.raise_for_status()
        
        # 解析响应
        result = response.json()
        
        # 检查响应状态
        if result.get("base_resp", {}).get("status_code") != 0:
            error_msg = result.get("base_resp", {}).get("status_msg", "未知错误")
            raise Exception(f"API请求失败: {error_msg}")
        
        # 获取音频数据
        audio_hex = result.get("data", {}).get("audio")
        if not audio_hex:
            raise Exception("未收到有效的音频数据")
        
        # 将hex转换为二进制并保存为MP3文件
        audio_binary = hex_to_binary(audio_hex)
        with open(output_file, "wb") as f:
            f.write(audio_binary)
        
        # 获取额外信息
        extra_info = result.get("extra_info", {})
        audio_length = extra_info.get("audio_length", 0)
        word_count = extra_info.get("word_count", 0)
        
        print(f"语音合成成功!")
        print(f"输出文件: {output_file}")
        print(f"音频时长: {audio_length} 毫秒")
        print(f"字数统计: {word_count}")
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"网络请求错误: {e}")
    except json.JSONDecodeError as e:
        raise Exception(f"JSON解析错误: {e}")
    except Exception as e:
        raise Exception(f"TTS合成失败: {e}")

def main():
    parser = argparse.ArgumentParser(description="Minimaxi TTS 文本转语音工具")
    parser.add_argument("--txt", required=True, help="要转换为语音的文本")
    parser.add_argument("--output", required=True, help="输出MP3文件路径")
    parser.add_argument("--api_key", help="Minimaxi API密钥 (也可通过MINIMAXI_API_KEY环境变量设置)")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"模型版本 (默认: {DEFAULT_MODEL})")
    parser.add_argument("--voice_id", default=DEFAULT_VOICE_ID, help=f"音色ID (默认: {DEFAULT_VOICE_ID})")
    parser.add_argument("--speed", type=float, default=1.0, help="语音速度，范围 0.5-2.0 (默认: 1.0)")
    
    args = parser.parse_args()
    
    # 获取API密钥
    api_key = args.api_key or os.getenv("MINIMAXI_API_KEY")
    if not api_key:
        print("错误: 请提供Minimaxi API密钥，可通过 --api_key 参数或 MINIMAXI_API_KEY 环境变量设置", file=sys.stderr)
        sys.exit(1)
    
    # 检查文本长度
    if len(args.txt) >= 10000:
        print("警告: 文本长度超过10000字符限制，可能会导致API调用失败", file=sys.stderr)

    # 验证速度参数
    if args.speed < 0.5 or args.speed > 2.0:
        print("错误: speed 参数必须在 0.5-2.0 范围内", file=sys.stderr)
        sys.exit(1)
    
    try:
        tts_synthesis(
            api_key=api_key,
            text=args.txt,
            output_file=args.output,
            model=args.model,
            voice_id=args.voice_id,
            speed=args.speed
        )
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
