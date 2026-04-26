# Implementation Plan: Implement Feedback Loop and Advanced Montage Orchestration

## Phase 1: Interactive Feedback Loop
- [x] Task: Implement `Arneis::Cli#feedback` command. a032915
- [x] Task: Use Gemini to identify `asset_id` from user prompt. a032915
- [x] Task: Implement `.trash/` archiving for assets and receipts. a032915
- [x] Task: Update `.state.yaml` to reset target asset status to `pending`. a032915
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Advanced Montage & LLM Commands
- [ ] Task: Implement LLM-driven `ffmpeg` command generation in `VideoProject`.
- [ ] Task: Enhance `VideoProject#process` to execute the generated montage command.
- [ ] Task: Verify montage with background music juxtaposition.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Visual Polish & Folder Organization
- [ ] Task: Move `graph.md` generation into the project output folder.
- [ ] Task: Add media type emojis (🎥, 🎵, 📝) to `status` and `graph.md`.
- [ ] Task: Ensure project-level tasks (music, montage) are correctly tracked and displayed.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
