# Implementation Plan: Better Producer Strategy

## Phase 1: Iterative Planning & Hydration
- [x] Task: Create `Arneis::Planner` class to manage versioned Markdown plans. f5ab175
- [x] Task: Implement `__revN.md` naming and `rev: N` metadata extraction. f5ab175
- [x] Task: Write Tests for `Arneis::Planner` (Revision invalidation and versioning). f5ab175
- [x] Task: Implement hydration logic to detect segment changes between revisions. 8e3a2b6
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Post-Production (GIFs)
- [x] Task: Implement `Arneis::Generator::Gif` using `ffmpeg`. da78481
- [ ] Task: Add task dependency to trigger GIF generation after final video assembly.
- [x] Task: Write Tests for `Arneis::Generator::Gif` (Ensuring real .gif output). da78481
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Marketing Asset Generation
- [x] Task: Implement platform-specific prompt templates for LinkedIn, IG, and X. 442b2c5
- [x] Task: Update `Arneis::Generator::Imagen` to support multiple aspect ratios (9:16 for IG). 442b2c5
- [x] Task: Write Tests for `Arneis::Generator::Marketing` (Asset existence and naming). 442b2c5
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Folder Refurbishment & Orchestration
- [~] Task: Update `Arneis::VideoProject` to use the new subfolder structure (`video/scenex/`, `marketing/`).
- [ ] Task: Ensure all generators respect the unified project folder while writing to subdirectories.
- [ ] Task: Integrate marketing and GIF tasks into the main `Orchestrator` flow.
- [ ] Task: Final end-to-end verification with `just arnectl apply`.
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
