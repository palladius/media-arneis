#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
#     "python-dotenv",
# ]
# ///
"""
Arneis Video Generator - PRO version.
Uses Google Veo via Vertex AI with full control.
"""
import argparse
import base64
import os
import sys
import time
from google import genai
from google.genai import types
from dotenv import load_dotenv

def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Generate high-fidelity videos using Google Veo.")
    parser.add_argument("prompt", type=str, help="The text prompt for video generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file path.")
    parser.add_argument("-i", "--image", type=str, help="Path to a reference image for style/consistency.")
    parser.add_argument("-d", "--duration", type=str, default="8", help="Duration in seconds (5 or 8).")
    parser.add_argument("-m", "--model", type=str, default="veo-3.1-fast-generate-001", help="Model ID.")
    
    args = parser.parse_args()

    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    location = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
    
    client = genai.Client(vertexai=True, project=project, location=location)

    print(f"🎥 [PRO] Generating video for: '{args.prompt}'", file=sys.stderr)
    
    request_data = {
        "instances": [{"prompt": args.prompt}],
        "parameters": {
            "sampleCount": 1,
            "durationSeconds": int(args.duration),
            "fps": 24,
            "generateAudio": True,
        }
    }

    if args.image and os.path.exists(args.image):
        print(f"👤 Using reference image: {args.image}", file=sys.stderr)
        with open(args.image, "rb") as f:
            request_data["instances"][0]["image"] = base64.b64encode(f.read()).decode("utf-8")

    try:
        # Predict Long Running for Veo
        operation = client.models.predict_long_running(
            model=args.model,
            **request_data
        )

        print(f"⏳ Operation started: {operation.name}", file=sys.stderr)
        
        # Poll for completion
        while not operation.done:
            print("  Polling...", file=sys.stderr)
            time.sleep(10)
            operation = client.operations.get(operation.name)

        if operation.error:
            raise ValueError(f"API Error: {operation.error.message}")

        # Extract video from result
        video_data = operation.result.videos[0]
        if video_data.bytes_base64_encoded:
            with open(args.output, "wb") as f:
                f.write(base64.b64decode(video_data.bytes_base64_encoded))
            print(f"🎞️ Saved to {args.output}", file=sys.stderr)
            print(f"MEDIA:{args.output}")
            sys.exit(0)
        else:
            raise ValueError("No video data in response.")

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
