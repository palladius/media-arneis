#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-cloud-texttospeech",
# ]
# ///
"""
Arneis Audio Generator - Uses Google Cloud TTS (Chirp 2).
"""
import sys
import argparse
import os
from google.cloud import texttospeech

def main():
    parser = argparse.ArgumentParser(description="Generate audio using Google Cloud TTS.")
    parser.add_argument("-t", "--text", type=str, required=True, help="Text to speak.")
    parser.add_argument("-l", "--lang", type=str, default="en-US", help="Language code.")
    parser.add_argument("-v", "--voice", type=str, help="Voice ID.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output path.")
    
    args = parser.parse_args()

    print(f"🗣️  Generating audio for text: '{args.text[:50]}...' in {args.lang}...", file=sys.stderr)
    
    try:
        client = texttospeech.TextToSpeechClient()

        synthesis_input = texttospeech.SynthesisInput(text=args.text)

        # Build the voice request
        # Note: We use the language code provided. If voice is provided, we use it.
        voice = texttospeech.VoiceSelectionParams(
            language_code=args.lang,
            name=args.voice
        )

        # Select the type of audio file you want returned
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.LINEAR16
        )

        # Perform the text-to-speech request
        response = client.synthesize_speech(
            input=synthesis_input, voice=voice, audio_config=audio_config
        )

        # The response's audio_content is binary.
        with open(args.output, "wb") as out:
            out.write(response.audio_content)
            print(f"🎵 Audio saved to {args.output}", file=sys.stderr)

        print(f"MEDIA:{args.output}")
        sys.exit(0)

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
