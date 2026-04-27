# Implementation Plan: KidsStory Multilingual Audio Generation & Eval-Driven Redo

## Phase 1: Configuration & YAML Parsing
- [~] Task: Update YAML Schema and Parser for `story_audio`
    - [ ] Write failing test for parsing `story_audio` array in `KidsStory` config, ensuring it defaults to `[it, en]`.
    - [ ] Implement parsing logic (e.g., in `lib/arneis/kids_story.rb`).
    - [x] Update `data/samples/KidsStory/riccardo_story.yaml` and `yukihiro_story.yaml` to include `story_audio: [it, en]`.
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Configuration & YAML Parsing' (Protocol in workflow.md)

## Phase 2: Paragraph-level Audio Generation Pipeline
- [ ] Task: Implement Translation and Audio Generation Orchestration
    - [ ] Write failing test to verify the audio generation trigger is called for each page when `story_audio` is present.
    - [ ] Implement a hardcoded Voice Mapping (Language -> Voice ID) for Chirp 2.
    - [ ] Implement paragraph translation using the Gemini LLM.
    - [ ] Implement the TTS call to Chirp 2 using the consistent voice.
    - [ ] Ensure generated audio files are saved correctly inside their respective `pageXX/` directories.
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Paragraph-level Audio Generation Pipeline' (Protocol in workflow.md)

## Phase 3: Final Audio Concatenation & Feedback
- [ ] Task: Implement Deterministic Audio Concatenation
    - [ ] Write failing test for concatenating individual page audio files into a single story audio file.
    - [ ] Implement the audio concatenation logic.
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Final Audio Concatenation & Feedback' (Protocol in workflow.md)

## Phase 4: Status Output & Auto-Invalidation Suggestion
- [ ] Task: Implement Eval Threshold detection in `arnectl status`
    - [ ] Write failing test for `arnectl status` to check if it detects scores < 6 and suggests a redo command.
    - [ ] Implement the UI message in the `status` command output.
- [ ] Task: Implement `arnectl redo --threshold` logic
    - [ ] Write failing test for `arnectl redo --threshold 6` verifying it invalidates only sub-optimal artifacts.
    - [ ] Implement the invalidation logic (moving files to `.trash` or marking as invalid in metadata).
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Status Output & Auto-Invalidation Suggestion' (Protocol in workflow.md)