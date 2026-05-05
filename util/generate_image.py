#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
#     "python-dotenv",
#     "pillow",
# ]
# ///
"""
Arneis Image Generator - Gemini 3.1 Flash Image (Multimodal).
The proven approach for 90%+ character consistency.
Uses non-Vertex GenAI API.
"""
import sys
import argparse
import os
from google import genai
from google.genai import types
from dotenv import load_dotenv
import base64

def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Generate high-fidelity images with character consistency.")
    parser.add_argument("-p", "--prompt", type=str, required=True, help="The text prompt for generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file path.")
    parser.add_argument("-i", "--images", nargs='*', help="Comma-separated paths to reference images for character consistency.")
    parser.add_argument("-a", "--aspect-ratio", type=str, default="1:1", help="Aspect ratio (1:1, 4:3, 3:4, 16:9, 9:16).")
    default_model = os.environ.get("ARNEIS_IMAGEN_MODEL", "gemini-3.1-flash-image-preview")
    parser.add_argument("-m", "--model", type=str, default=default_model, help="Model ID to use.")
    parser.add_argument("-v", "--vertex", action="store_true", default=False, help="Use Vertex AI.")

    args = parser.parse_args()

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("❌ Error: GEMINI_API_KEY not set.", file=sys.stderr)
        sys.exit(1)
        
    client = genai.Client(api_key=api_key)

    print(f"🎨 Generating image via multimodal prompt using {args.model}...", file=sys.stderr)
    
    contents = []

    # Add images as parts of the prompt
    if args.images:
        for img_path in args.images:
            img_path = img_path.strip()
            if os.path.exists(img_path):
                print(f"👤 Adding reference image for CC: {img_path}", file=sys.stderr)
                with open(img_path, "rb") as f:
                    image_data = f.read()
                    ext = os.path.splitext(img_path)[1].lower()
                    mime_type = "image/png" if ext == ".png" else "image/jpeg"
                    contents.append(types.Part.from_bytes(data=image_data, mime_type=mime_type))
    
    # Precise instruction for character consistency
    full_prompt = f"Using the provided reference images of the same person, generate a new image matching this description: {args.prompt}. It is CRITICAL that the generated person has the EXACT same facial features, hair, and build as the reference person. Unless the prompt specifies otherwise, the style MUST be PHOTOREALISTIC and highly detailed, avoiding any cartoon, anime, or stylized artistic effects. Output ONLY the image."
    contents.append(full_prompt)

    try:
        response = client.models.generate_content(
            model=args.model,
            contents=contents,
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE"],
                image_config=types.ImageConfig(
                    aspect_ratio=args.aspect_ratio
                )
            )
        )

        image_saved = False
        if not response.parts:
             print("⚠️ No parts in response. Refusal or safety filter hit.", file=sys.stderr)
             sys.exit(1)

        for part in response.parts:
            if part.inline_data:
                image_data = part.inline_data.data
                if isinstance(image_data, str):
                    image_data = base64.b64decode(image_data)
                
                with open(args.output, "wb") as f:
                    f.write(image_data)
                # Only color the output path in ANSI Bold (\033[1m) Bright Yellow (\033[93m)
                print(f"🖼️ Saved to \033[1;93m{args.output}\033[0m", file=sys.stderr)
                print(f"MEDIA:{args.output}")
                image_saved = True
                break

        if not image_saved:
            print("⚠️ No image returned in response parts.", file=sys.stderr)
            sys.exit(1)

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
