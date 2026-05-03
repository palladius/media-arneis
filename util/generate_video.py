#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
#     "python-dotenv",
# ]
# ///
"""
Arneis Video Generator - FIXED version.
Uses Google Veo via Vertex AI with correct generate_videos SDK call.
"""
import argparse
import os
import sys
import time
from google import genai
from google.genai import types
from dotenv import load_dotenv

def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Generate high-fidelity videos using Google Veo.")
    parser.add_argument("prompt", type=str, nargs='?', help="The text prompt for video generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file path.")
    parser.add_argument("-i", "--image", type=str, help="Path to a reference image.")
    default_model = os.environ.get("ARNEIS_VEO_DEFAULT_MODEL", "veo-3.0-generate-001")
    parser.add_argument("-m", "--model", type=str, default=default_model, help="Model ID.")
    parser.add_argument("--async-only", action="store_true", help="Start the operation and exit immediately.")
    parser.add_argument("--check-status", type=str, help="Check status of an existing operation.")
    
    args = parser.parse_args()

    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    location = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
    
    client = genai.Client(vertexai=True, project=project, location=location)

    if args.check_status:
        print(f"🔍 Checking status for: {args.check_status}", file=sys.stderr)
        # Construct the full operation resource name
        operation_resource_name = f"projects/{project}/locations/{location}/operations/{args.check_status}"
        op_status = client.operations.get(operation_resource_name)
        
        if op_status.done:
            if op_status.error:
                print(f"❌ Error: {op_status.error.message}", file=sys.stderr)
                sys.exit(1)
            # Process result
            if op_status.result and op_status.result.generated_videos:
                video_part = op_status.result.generated_videos[0].video
                if video_part.bytes:
                    with open(args.output, "wb") as f:
                        f.write(video_part.bytes)
                    print(f"🎞️ Saved to {args.output}", file=sys.stderr)
                    print(f"MEDIA:{args.output}")
                    sys.exit(0)
            print("⚠️ Done but no results found.", file=sys.stderr)
            sys.exit(1)
        else:
            print("⏳ Still in progress.", file=sys.stderr)
            sys.exit(0)

    print(f"🎥 [VEO] Generating real video for: '{args.prompt}'", file=sys.stderr)
    
    config = types.GenerateVideosConfig(
        aspect_ratio="16:9",
        fps=24,
        generate_audio=True,
    )

    # Note: For image-to-video, some models expect the image in the content parts
    contents = [args.prompt]
    if args.image and os.path.exists(args.image):
        print(f"👤 Using reference image: {args.image}", file=sys.stderr)
        with open(args.image, "rb") as f:
            contents.append(types.Part.from_bytes(data=f.read(), mime_type="image/png"))

    try:
        # Correct SDK call: generate_videos
        operation = client.models.generate_videos(
            model=args.model,
            prompt=args.prompt,
            config=config
        )

        # In some versions, operation might be a string (name) or an object
        op_name = getattr(operation, 'name', operation)
        print(f"⏳ Operation started: {op_name}", file=sys.stderr)
        
        if args.async_only:
            print(f"OPERATION_ID:{op_name}") # Print full resource name
            sys.exit(0)

        # Poll for completion
        while True:
            # Refresh status using op_name
            op_status = client.operations.get(op_name)
            if op_status.done:
                break
            print("  Polling...", file=sys.stderr)
            time.sleep(15)

        if op_status.error:
            raise ValueError(f"API Error: {op_status.error.message}")

        # The result structure for generate_videos contains generated_videos list
        if op_status.result and op_status.result.generated_videos:
            # We assume it saves to GCS by default or returns bytes
            # If it returns bytes in the video object:
            video_part = op_status.result.generated_videos[0].video
            if video_part.bytes:
                with open(args.output, "wb") as f:
                    f.write(video_part.bytes)
                print(f"🎞️ Saved to {args.output}", file=sys.stderr)
                print(f"MEDIA:{args.output}")
                sys.exit(0)
            else:
                # Some models only return a URI if output_gcs_uri was specified
                print(f"⚠️ Video URI: {video_part.uri}", file=sys.stderr)
                raise ValueError("No video bytes in response.")
        else:
            raise ValueError("No video generated in response.")

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
