# Video Project User Manual 🎥

This document outlines the current capabilities and usage of the Arneis Video Project orchestration.

## 🚀 Current Status (as of 2026-04-19)

### 1. Can we create videos? 🟡 **In Progress**
- **Orchestration:** Fully functional. `arnectl` can coordinate multiple scenes in parallel.
- **Real Generation:** `Arneis::Generator::Veo` is integrated via `util/generate_video.py`.
- **Known Issues:** Currently hitting 404 errors on Vertex AI for some model versions. The system automatically falls back to `.mock` files so the pipeline doesn't break.

### 2. Can we create music? 🟢 **Functional**
- **Real Generation:** `Arneis::Generator::Lyria` is fully functional via `util/generate_music.py`.
- **Success:** Real `.wav`/`.mp3` files are being generated and verified.

### 3. Can we assemble the final video? 🟡 **Partial**
- **Mechanism:** Gemini generates a pure `ffmpeg` filter-complex command based on the scenes and music.
- **Execution:** The system attempts to run this command.
- **Limitation:** If real video files are missing (due to 404s), `ffmpeg` will fail. In this case, the system creates a `final_video.mp4.mock` to allow the project to reach "done" status.

### 4. Can we say "redo video XYZ"? 🟢 **Functional**
- **Command:** `arnectl feedback -p video3` (or "Redo the third video, it's too dark").
- **Action:** 
  1. Archives the existing `scene_3.mp4` to `.trash/`.
  2. Resets the status to `pending` in `.state.yaml`.
  3. Run `arnectl resume` to trigger a fresh generation.

---

## 🛠️ Usage Guide

### Creating a New Project
```bash
# Timestamped folder (Default)
just arnectl apply data/samples/VideoProject/rubycon_sales_pitch.yaml

# Fixed folder (Best for testing/iterating)
just arnectl apply data/samples/VideoProject/rubycon_sales_pitch.yaml -o out/my-test-project
```

### Checking Status
```bash
# See ⚖️ for verified, 🤡 for mocked, 🚫 for invalid
just arnectl status out/my-test-project
```

### Redoing an Asset
```bash
# Target a specific scene
just arnectl feedback out/my-test-project -p "video2"

# Resume to regenerate only the pending items
just arnectl resume out/my-test-project
```

### Clean Up
```bash
# Archive empty/broken projects to out/archived/
just arnectl cleanup
```
