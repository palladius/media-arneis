# Implementation Plan: KidsStory Multilingual Audio Generation & Eval-Driven Redo

## Phase 1: Configuration & YAML Parsing
- [x] Task: Update YAML Schema and Parser for `story_audio` [33cdc4e]
    - [x] Write failing test for parsing `story_audio` array in `KidsStory` config, ensuring it defaults to `[it, en]`.
    - [x] Implement parsing logic (e.g., in `lib/arneis/kids_story.rb`).
    - [x] Update `data/samples/KidsStory/riccardo_story.yaml` and `yukihiro_story.yaml` to include `story_audio: [it, en]`.
    - [x] Refactor and ensure all tests pass.
- [x] Task: Conductor - User Manual Verification 'Configuration & YAML Parsing' (Protocol in workflow.md)

## Phase 2: Paragraph-level Audio Generation Pipeline
- [x] Task: Implement Translation and Audio Generation Orchestration [4390a46]
    - [x] Write failing test to verify the audio generation trigger is called for each page when `story_audio` is present.
    - [x] Implement a hardcoded Voice Mapping (Language -> Voice ID) for Chirp 2.
    - [x] Implement paragraph translation using the Gemini LLM.
    - [x] Implement the TTS call to Chirp 2 using the consistent voice.
    - [x] Ensure generated audio files are saved correctly inside their respective `pageXX/` directories.
    - [x] Refactor and ensure all tests pass.
- [x] Task: Conductor - User Manual Verification 'Paragraph-level Audio Generation Pipeline' (Protocol in workflow.md)

## Phase 3: Final Audio Concatenation & Feedback
- [x] Task: Implement Deterministic Audio Concatenation [c026536]
    - [x] Write failing test for concatenating individual page audio files into a single story audio file.
    - [x] Implement the audio concatenation logic.
    - [x] Refactor and ensure all tests pass.
- [x] Task: Conductor - User Manual Verification 'Final Audio Concatenation & Feedback' (Protocol in workflow.md)

## Phase 4: Status Output & Auto-Invalidation Suggestion
- [x] Task: Implement Eval Threshold detection in `arnectl status` [9ebbe88]
    - [x] Write failing test for `arnectl status` to check if it detects scores < 6 and suggests a redo command.
    - [x] Implement the UI message in the `status` command output.
- [x] Task: Implement `arnectl redo --threshold` logic [9ebbe88]
    - [x] Write failing test for `arnectl redo --threshold 6` verifying it invalidates only sub-optimal artifacts.
    - [x] Implement the invalidation logic (moving files to `.trash` or marking as invalid in metadata).
    - [x] Refactor and ensure all tests pass.
- [x] Task: Conductor - User Manual Verification 'Status Output & Auto-Invalidation Suggestion' (Protocol in workflow.md) [9ebbe88]