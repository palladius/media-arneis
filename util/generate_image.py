# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
# ]
# ///
"""
Arneis Image Generator - Uses Google Imagen via GenAI SDK (Vertex).
"""
import sys
import argparse
import os
import base64
from google import genai

def main():
    parser = argparse.ArgumentParser(description="Generate images using Google Imagen via GenAI SDK.")
    parser.add_argument("prompt", type=str, help="Image prompt.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output path.")
    
    args = parser.parse_args()

    # Determine project and region from environment
    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    location = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
    model_id = "gemini-2.0-flash-exp" 

    client = genai.Client(vertexai=True, project=project, location=location)
    
    print(f"🎨 Generating image for prompt: '{args.prompt}'...", file=sys.stderr)
    try:
        # Use generate_content for multimodal output
        response = client.models.generate_content(
            model=model_id,
            contents=args.prompt
        )

        found_image = False
        if not response.candidates or not response.candidates[0].content.parts:
            print("⚠️ No content returned.", file=sys.stderr)
            sys.exit(1)

        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                with open(args.output, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"🖼️ Image saved to {args.output}", file=sys.stderr)
                found_image = True

        if found_image:
            print(f"MEDIA:{args.output}")
            sys.exit(0)
        else:
            print("⚠️ No image generated.", file=sys.stderr)
            sys.exit(1)

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
