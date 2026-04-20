# Track Specification: Better Producer Strategy

## Overview
This track enhances the video production workflow by introducing iterative planning, automated post-production (GIFs), and cross-platform marketing asset generation. It aligns the orchestrator with the `genmedia-video-editor` guidelines.

## Functional Requirements
1. **Iterative Planning (Revisions):**
   - Implement `Arneis::Planner` to generate versioned Markdown plans using the `__revN.md` suffix (e.g., `plan__rev1.md`).
   - Each plan MUST contain a `rev: N` field in its metadata/frontmatter.
   - **Invalidation Logic:** A higher revision number (e.g., rev 2) automatically invalidates all lower revisions (e.g., rev 1).
   - The plan MUST include segment breakdowns, music, and VO scripts.
2. **Automated GIF Post-Production:**
   - Immediately after the final video is assembled, trigger a `ffmpeg` task to generate a high-quality `.gif` of the full video.
3. **Cross-Platform Marketing Assets:**
   - Generate platform-specific marketing images using `Arneis::Generator::Imagen`:
     - **LinkedIn:** Professional, infographic-style, formal hashtags.
     - **Instagram/FB Stories:** 9:16 vertical, visual-heavy, lifestyle-driven.
     - **X / Twitter:** Punchy, short-form text, hashtag-optimized.
4. **Enhanced Organization:**
   - Unified project folder (e.g., `out/YYYYMMDD_project_name/`).
   - Media components organized into subfolders: `video/scene1/`, `video/scene2/`, etc.
   - Marketing assets in a dedicated `marketing/` subfolder.

## Acceptance Criteria
- [ ] `arnectl apply` creates an initial `plan__rev1.md`.
- [ ] Unit tests confirm that `plan__rev1.md` contains `rev: 1`.
- [ ] Updating to `plan__rev2.md` causes the system to ignore `plan__rev1.md`.
- [ ] `final_video.gif` exists in the output folder.
- [ ] `marketing/` folder contains distinct assets for LinkedIn, IG, and X.

## Out of Scope
- Direct API posting to social platforms (local generation only).
