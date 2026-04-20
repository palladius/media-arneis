# Implementation Plan: Better Producer Strategy

## Phase 1: Iterative Planning & Hydration
- [x] Task: Create `Arneis::Planner` class to manage versioned Markdown plans. f5ab175
- [x] Task: Implement `__revN.md` naming and `rev: N` metadata extraction. f5ab175
- [x] Task: Write Tests for `Arneis::Planner` (Revision invalidation and versioning). f5ab175
- [~] Task: Implement hydration logic to detect segment changes between revisions.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Post-Production (GIFs)
- [ ] Task: Implement `Arneis::Generator::Gif` using `ffmpeg`.
- [ ] Task: Add task dependency to trigger GIF generation after final video assembly.
- [ ] Task: Write Tests for `Arneis::Generator::Gif` (Ensuring real .gif output).
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Marketing Asset Generation
- [ ] Task: Implement platform-specific prompt templates for LinkedIn, IG, and X.
- [ ] Task: Update `Arneis::Generator::Imagen` to support multiple aspect ratios (9:16 for IG).
- [ ] Task: Write Tests for `Arneis::Generator::Marketing` (Asset existence and naming).
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Folder Refurbishment & Orchestration
- [ ] Task: Update `Arneis::VideoProject` to use the new subfolder structure (`video/scenex/`, `marketing/`).
- [ ] Task: Ensure all generators respect the unified project folder while writing to subdirectories.
- [ ] Task: Integrate marketing and GIF tasks into the main `Orchestrator` flow.
- [ ] Task: Final end-to-end verification with `just arnectl apply`.
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
