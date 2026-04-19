# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
Arneis Video Generator - Uses Google Veo via gcloud.
"""
import argparse
import base64
import os
import sys
import time
import subprocess
import json

def main():
    parser = argparse.ArgumentParser(description="Generate a video using Google's Veo model.")
    parser.add_argument("prompt", type=str, help="The text prompt for video generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output path.")
    
    args = parser.parse_args()

    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    location = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
    model_id = "veo-2.0-generate-001" 

    print(f"🎥 Generating video for prompt: '{args.prompt}'...", file=sys.stderr)
    
    payload = {
        "instances": [{"prompt": args.prompt}],
        "parameters": {"sampleCount": 1}
    }
    
    with open("video_payload.json", "w") as f:
        json.dump(payload, f)
        
    cmd = [
        "gcloud", "ai", "models", "predict", model_id,
        f"--region={location}",
        f"--project={project}",
        "--json-request=video_payload.json"
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        resp = json.loads(result.stdout)
        
        if "predictions" in resp:
            video_bytes = resp["predictions"][0].get("bytesBase64Encoded")
            if video_bytes:
                with open(args.output, "wb") as f:
                    f.write(base64.b64decode(video_bytes))
                print(f"🎞️ Video saved to {args.output}", file=sys.stderr)
                print(f"MEDIA:{args.output}")
                sys.exit(0)
                
        print("⚠️ No video data in response.", file=sys.stderr)
        sys.exit(1)

    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        sys.exit(1)
    finally:
        if os.path.exists("video_payload.json"):
            os.remove("video_payload.json")

if __name__ == "__main__":
    main()
