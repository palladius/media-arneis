# /// script
# dependencies = [
#   "requests",
#   "google-auth",
#   "google-cloud-storage",
# ]
# ///
"""
Arneis Video Generator - Uses Google Veo via Vertex AI.
"""
import argparse
import base64
import os
import re
import sys
import time
import requests
import subprocess

# Constants from Config or Environment
LOCATION_ID = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
VEO_MODEL_ID = "veo-3.1-fast-generate-001"
VEO_PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")

def get_access_token():
    try:
        token = subprocess.check_output("gcloud auth print-access-token", shell=True, text=True).strip()
        return token
    except subprocess.CalledProcessError as e:
        print(f"Error getting gcloud access token: {e}", file=sys.stderr)
        sys.exit(1)

def async_trigger_video_generation(prompt: str) -> str:
    access_token = get_access_token()
    headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
    
    request_data = {
        "instances": [{"prompt": prompt}],
        "parameters": {
            "aspectRatio": "16:9",
            "sampleCount": 1,
            "durationSeconds": "8",
            "fps": "24",
            "generateAudio": True,
        },
    }

    url = f"https://{LOCATION_ID}-aiplatform.googleapis.com/v1/projects/{VEO_PROJECT_ID}/locations/{LOCATION_ID}/publishers/google/models/{VEO_MODEL_ID}:predictLongRunning"
    response = requests.post(url, headers=headers, json=request_data)
    response.raise_for_status()
    return response.json()["name"]

def retrieve_video_status(operation_id: str) -> dict:
    access_token = get_access_token()
    headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
    
    # Normalize operation_id to standard Vertex AI operation path
    # Remove "publishers/google/models/..." from the operation name if it exists.
    # Example input: projects/PROJ/locations/LOC/publishers/google/models/MODEL/operations/OP_ID
    # Output: projects/PROJ/locations/LOC/operations/OP_ID
    normalized_id = re.sub(r"/publishers/google/models/[^/]+/", "/", operation_id)
    
    url = f"https://{LOCATION_ID}-aiplatform.googleapis.com/v1/{normalized_id}"
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()

def main():
    parser = argparse.ArgumentParser(description="Generate a video using Google's Veo model.")
    parser.add_argument("prompt", type=str, help="The text prompt for video generation.")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output path.")
    
    args = parser.parse_args()
    
    try:
        operation_name = async_trigger_video_generation(args.prompt)
        print(f"⏳ Video generation started. Operation: {operation_name}", file=sys.stderr)
        
        for i in range(60):
            print(f"Polling attempt {i+1}/60...", file=sys.stderr)
            status = retrieve_video_status(operation_name)
            
            if status.get("done"):
                if "error" in status:
                    raise ValueError(f"API Error: {status['error'].get('message')}")
                
                # Veo typically returns videos in the 'response' block
                video_data = status.get("response", {}).get("videos", [{}])[0]
                if "bytesBase64Encoded" in video_data:
                    with open(args.output, "wb") as f:
                        f.write(base64.b64decode(video_data["bytesBase64Encoded"]))
                    print(f"MEDIA:{args.output}")
                    sys.exit(0)
                else:
                    raise ValueError("Video data not found in response.")
            
            time.sleep(10)
            
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
