# Implementation Plan: E2E Testing & Mock Abolition

## Phase 1: Mock Abolition Logic
- [x] Task: Implement `ARNEIS_NO_MOCK` configuration in `Arneis::Config` ca93f5a
- [~] Task: Update Generators to raise errors instead of creating mocks when `no_mock?` is true
    - [ ] Update `Imagen` generator
    - [ ] Update `Chirp` generator
    - [ ] Update `Lyria` generator
    - [ ] Update `Veo` generator
- [ ] Task: Conductor - User Manual Verification 'Mock Abolition' (Protocol in workflow.md)

## Phase 2: KidsStory E2E Testing
- [x] Task: Create `spec/e2e/kids_story_e2e_spec.rb`
- [ ] Task: Implement independent E2E test for `KidsStory`
    - [ ] Use `data/samples/KidsStory/riccardo_story.yaml`
    - [ ] Set `ARNEIS_NO_MOCK=true`
    - [ ] Verify creation of real `.png`, `.wav`, and `.md` files
    - [ ] Verify `.asset.json` evaluation content
- [ ] Task: Conductor - User Manual Verification 'KidsStory E2E' (Protocol in workflow.md)

## Phase 3: VideoProject E2E Testing
- [x] Task: Create `spec/e2e/video_project_e2e_spec.rb`
- [ ] Task: Implement independent E2E test for `VideoProject`
    - [ ] Use a small sample YAML (e.g., `data/samples/VideoProject/rubycon_pitch.yaml`)
    - [ ] Set `ARNEIS_NO_MOCK=true`
    - [ ] Verify creation of real `.mp4` and `.wav` files
- [ ] Task: Conductor - User Manual Verification 'VideoProject E2E' (Protocol in workflow.md)

## Phase 4: CI/CD & Documentation
- [ ] Task: Add `just test-expensive` to run the E2E suite
- [ ] Task: Update `README.md` with E2E testing instructions
- [ ] Task: Final verification and cleanup
