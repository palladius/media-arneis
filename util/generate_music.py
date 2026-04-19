#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
# ]
# ///
"""
Arneis Music Generator - Uses Google Lyria via GenAI SDK.
"""
import sys
import argparse
import os
from google import genai
from google.genai import types

def main():
    parser = argparse.ArgumentParser(description="Generate music using Google Lyria.")
    parser.add_argument("-p", "--prompt", type=str, required=True, help="Music prompt.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output path.")
    
    args = parser.parse_args()

    # Determine project and region from environment
    client = genai.Client(vertexai=False) # Use Generative Language API

    print(f"🎸 Generating music for prompt: '{args.prompt}'...", file=sys.stderr)
    try:
        response = client.models.generate_content(
            model="lyria-3-clip-preview",
            contents=args.prompt,
            config=types.GenerateContentConfig(
                response_modalities=["AUDIO", "TEXT"],
            ),
        )

        found_audio = False
        if not response.candidates or not response.candidates[0].content.parts:
            print("⚠️ No content returned.", file=sys.stderr)
            sys.exit(1)

        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                with open(args.output, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"🎵 Audio saved to {args.output}", file=sys.stderr)
                found_audio = True

        if found_audio:
            print(f"MEDIA:{args.output}")
            sys.exit(0)
        else:
            print("⚠️ No audio generated.", file=sys.stderr)
            sys.exit(1)

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
