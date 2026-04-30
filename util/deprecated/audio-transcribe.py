#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
# ]
# ///
"""
Arneis Audio transcriber - Uses Gemini Multimodal to transcribe audio.
"""
import sys
import argparse
import os
import base64
from google import genai
from google.genai import types

def main():
    parser = argparse.ArgumentParser(description="Transcribe audio using Google Gemini.")
    parser.add_argument("file", type=str, help="Path to the audio file.")
    default_model = os.environ.get("ARNEIS_MAIN_MODEL", "gemini-2.5-flash")
    parser.add_argument("-m", "--model", type=str, default=default_model, help=f"Gemini model to use (default: {default_model}).")
    
    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"❌ Error: File {args.file} not found.", file=sys.stderr)
        sys.exit(1)

    # Initialize client
    client = genai.Client(vertexai=False) 

    print(f"🧠 Transcribing {args.file} using {args.model}...", file=sys.stderr)
    
    try:
        with open(args.file, "rb") as f:
            audio_data = f.read()

        response = client.models.generate_content(
            model=args.model,
            contents=[
                types.Part.from_bytes(data=audio_data, mime_type="audio/wav"),
                "What does this audio file say? Please provide a clean transcription."
            ]
        )

        if not response.text:
            print("⚠️ No transcription returned.", file=sys.stderr)
            sys.exit(1)

        print("\n--- TRANSCRIPTION ---")
        print(response.text.strip())
        print("----------------------")

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
