#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
# ]
# ///
import os
from google import genai

client = genai.Client(vertexai=False)
print("Available Models (GenAI API):")
for m in client.models.list():
    print(f"- {m.name}")
