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
Arneis Image Generator - PRO version.
Supports character consistency using multi-image input.
"""
import sys
import argparse
import os
from google import genai
from google.genai import types
from dotenv import load_dotenv
from PIL import Image as PILImage
from io import BytesIO

def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Generate high-fidelity images with character consistency.")
    parser.add_argument("-p", "--prompt", type=str, required=True, help="The text prompt for generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file path.")
    parser.add_argument("-i", "--images", type=str, help="Comma-separated paths to reference images for character consistency.")
    parser.add_argument("-a", "--aspect-ratio", type=str, default="1:1", help="Aspect ratio (1:1, 4:3, 3:4, 16:9, 9:16).")
    parser.add_argument("-m", "--model", type=str, default="imagen-3.0-generate-001", help="Model ID to use.")
    parser.add_argument("-v", "--vertex", action="store_true", default=True, help="Use Vertex AI (default: True).")

    args = parser.parse_args()

    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    location = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
    api_key = os.getenv("GEMINI_API_KEY")
    
    if args.vertex:
        client = genai.Client(vertexai=True, project=project, location=location)
    else:
        client = genai.Client(api_key=api_key)

    print(f"🎨 Generating image for: '{args.prompt}' using {args.model}", file=sys.stderr)
    
    if args.model.startswith("imagen"):
        # Imagen-specific logic
        config = types.GenerateImagesConfig(
            number_of_images=1,
            aspect_ratio=args.aspect_ratio,
        )

        if args.images:
            image_paths = args.images.split(',')
            # In some SDK versions, it's person_generation = "ALLOW_ALL"
            config.person_generation = "ALLOW_ALL"
            
            # For character consistency, some versions use a list of reference images directly in a config
            # but let's try the multimodal prompt approach if possible, or check if generate_images accepts parts.
            # Actually, let's use Hussein's proven multimodal generate_content if it's gemini-*
            # For imagen-*, we might be limited to what GenerateImagesConfig supports.
        
        try:
            response = client.models.generate_images(
                model=args.model,
                prompt=args.prompt,
                config=config
            )
            if response.generated_images:
                with open(args.output, "wb") as f:
                    f.write(response.generated_images[0].image.image_bytes)
                print(f"🖼️ Saved to {args.output}", file=sys.stderr)
                print(f"MEDIA:{args.output}")
                return
        except Exception as e:
            print(f"❌ Imagen Error: {str(e)}", file=sys.stderr)
            sys.exit(1)

    else:
        # Gemini (Nano Banana) logic
        contents = []
        if args.images:
            image_paths = args.images.split(',')
            for img_path in image_paths:
                img_path = img_path.strip()
                if os.path.exists(img_path):
                    print(f"👤 Adding reference image for CC: {img_path}", file=sys.stderr)
                    with open(img_path, "rb") as f:
                        image_data = f.read()
                        contents.append(types.Part.from_bytes(data=image_data, mime_type="image/png"))
        
        contents.append(args.prompt)

        try:
            response = client.models.generate_content(
                model=args.model,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_modalities=["TEXT", "IMAGE"],
                    image_config=types.ImageConfig(
                        image_size="1K",
                        aspect_ratio=args.aspect_ratio
                    )
                )
            )

            for part in response.parts:
                if part.inline_data:
                    image_data = part.inline_data.data
                    if isinstance(image_data, str):
                        import base64
                        image_data = base64.b64decode(image_data)
                    
                    image = PILImage.open(BytesIO(image_data))
                    if image.mode != 'RGB':
                        image = image.convert('RGB')
                    image.save(args.output, "PNG")
                    print(f"🖼️ Saved to {args.output}", file=sys.stderr)
                    print(f"MEDIA:{args.output}")
                    return

        except Exception as e:
            print(f"❌ Gemini Error: {str(e)}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()
