# Implementation Plan: E2E Testing & Mock Abolition

## Phase 1: Mock Abolition Logic
- [x] Task: Implement `ARNEIS_NO_MOCK` configuration in `Arneis::Config` ca93f5a
- [x] Task: Update Generators to raise errors instead of creating mocks when `no_mock?` is true 2e8b120
    - [x] Update `Imagen` generator
    - [x] Update `Chirp` generator
    - [x] Update `Lyria` generator
    - [x] Update `Veo` generator
- [x] Task: Refine logic to allow mocks during `--dryrun` for better UX 46dee5b
- [x] Task: Conductor - User Manual Verification 'Mock Abolition' (Protocol in workflow.md)

## Phase 2: KidsStory E2E Testing
- [x] Task: Create `spec/e2e/kids_story_e2e_spec.rb` 2e8b120
- [x] Task: Implement independent E2E test for `KidsStory` 302b320
    - [x] Use `data/samples/KidsStory/riccardo_story.yaml`
    - [x] Set `ARNEIS_NO_MOCK=true`
    - [x] Verify creation of real `.png`, `.wav`, and `.md` files
    - [x] Verify `.asset.json` evaluation content
- [x] Task: Conductor - User Manual Verification 'KidsStory E2E' (Protocol in workflow.md)

## Phase 3: VideoProject E2E Testing
- [x] Task: Create `spec/e2e/video_project_e2e_spec.rb` 2e8b120
- [x] Task: Implement independent E2E test for `VideoProject` b52ec44
    - [x] Use a small sample YAML (e.g., `data/samples/VideoProject/rubycon_pitch.yaml`)
    - [x] Set `ARNEIS_NO_MOCK=true`
    - [x] Verify creation of real `.mp4` and `.wav` files
- [x] Task: Investigate and fix Veo generator issues for real video creation 343075c
    - [x] Add granular tests for `Veo` synchronous generation
    - [x] Add granular tests for `Veo` asynchronous initiation and status checking
- [x] Task: Conductor - User Manual Verification 'VideoProject E2E' (Protocol in workflow.md)

## Phase 4: CI/CD & Documentation
- [x] Task: Add `just test-e2e` to run the E2E suite in `Justfile`
- [x] Task: Update `README.md` with E2E testing instructions
- [x] Task: Final verification and cleanup
