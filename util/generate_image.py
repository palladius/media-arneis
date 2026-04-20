#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
#     "python-dotenv",
# ]
# ///
"""
Arneis Image Generator - PRO version.
Supports character consistency, styles, and high-fidelity generation.
"""
import sys
import argparse
import os
import base64
from google import genai
from google.genai import types
from dotenv import load_dotenv

def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Generate high-fidelity images using Google Imagen.")
    parser.add_argument("-p", "--prompt", type=str, required=True, help="The text prompt for generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file path.")
    parser.add_argument("-a", "--aspect-ratio", type=str, default="1:1", help="Aspect ratio (1:1, 4:3, 3:4, 16:9, 9:16).")
    parser.add_argument("-i", "--image", type=str, help="Path to a reference image for character consistency.")
    parser.add_argument("-s", "--style", type=str, help="Optional style reference (e.g., 'cinematic', 'watercolor').")
    parser.add_argument("-m", "--model", type=str, default="imagen-3.0-generate-001", help="Model ID to use.")
    parser.add_argument("-v", "--vertex", action="store_true", default=True, help="Use Vertex AI (default: True).")

    args = parser.parse_args()

    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    location = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
    
    client = genai.Client(vertexai=args.vertex, project=project, location=location)

    print(f"🎨 Generating image for: '{args.prompt}'", file=sys.stderr)
    
    # Handle reference image if provided
    parts = [args.prompt]
    if args.image and os.path.exists(args.image):
        print(f"👤 Using reference image: {args.image}", file=sys.stderr)
        with open(args.image, "rb") as f:
            parts.append(types.Part.from_bytes(data=f.read(), mime_type="image/png"))

    try:
        # Standard Imagen generation typically uses specific config
        response = client.models.generate_content(
            model=args.model,
            contents=parts,
            config=types.GenerateContentConfig(
                aspect_ratio=args.aspect_ratio
            )
        )

        found_image = False
        if response.candidates and response.candidates[0].content.parts:
            for part in response.candidates[0].content.parts:
                if part.inline_data:
                    with open(args.output, "wb") as f:
                        f.write(part.inline_data.data)
                    print(f"🖼️ Saved to {args.output}", file=sys.stderr)
                    print(f"MEDIA:{args.output}")
                    found_image = True
                    break

        if not found_image:
            print("⚠️ No image returned in response.", file=sys.stderr)
            sys.exit(1)

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
