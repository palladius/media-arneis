# Implementation Plan: Implement expensive, end-to-end LLM integration tests

## Phase 1: Core Test Infrastructure
- [ ] Task: Create `lib/arneis/test/base.rb` to house common test logic.
- [ ] Task: Create `lib/arneis/test/expensive_suite.rb` to orchestrate real generations.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Media Test Implementation
- [ ] Task: Implement `VideoGen` test (Veo).
- [ ] Task: Implement `ImageGen` and `ImageEdit` tests (Imagen).
- [ ] Task: Implement `AudioGen` (Lyria) and `TTS` (Chirp) tests.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: CLI & Justfile
- [ ] Task: Add `just-llm-tests` to the `Justfile`.
- [ ] Task: Implement summary report with timing and cost stats.
- [ ] Task: Verify opt-in mechanism works to protect user wallet.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
