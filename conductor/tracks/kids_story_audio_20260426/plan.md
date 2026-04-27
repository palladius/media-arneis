# Implementation Plan: KidsStory Multilingual Audio Generation

## Phase 1: Configuration & YAML Parsing
- [ ] Task: Update YAML Schema and Parser for `story_audio`
    - [ ] Write failing test for parsing `story_audio` array in `KidsStory` config, ensuring it defaults to `[it, en]`.
    - [ ] Implement parsing logic (e.g., in `lib/arneis/kids_story.rb` or schema validators).
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Configuration & YAML Parsing' (Protocol in workflow.md)

## Phase 2: Paragraph-level Audio Generation Pipeline
- [ ] Task: Implement Translation and Audio Generation Orchestration
    - [ ] Write failing test to verify the audio generation trigger is called for each paragraph/page when `story_audio` is present.
    - [ ] Write failing test for the translation step (translating paragraph text to target language).
    - [ ] Implement paragraph translation using the Gemini LLM.
    - [ ] Implement the TTS call to Chirp 2 for the translated text.
    - [ ] Ensure generated audio files are saved correctly inside their respective `pageXX/` directories (e.g., `page01/audio_en.wav`).
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Paragraph-level Audio Generation Pipeline' (Protocol in workflow.md)

## Phase 3: Final Audio Concatenation
- [ ] Task: Implement Deterministic Audio Concatenation
    - [ ] Write failing test for concatenating individual `pageXX/audio_<lang>.wav` files into a single `final_story_<lang>.wav`.
    - [ ] Implement the audio concatenation logic (e.g., using `ffmpeg` or a dedicated Ruby gem).
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Final Audio Concatenation' (Protocol in workflow.md)

## Phase 4: Feedback Loop Integration
- [ ] Task: Handle Partial Regenerations
    - [ ] Write failing test simulating a single page regeneration (e.g., "redo page 2"), verifying only page 2's text and audio are regenerated.
    - [ ] Write failing test verifying the final concatenated audio is correctly rebuilt using cached audio for unchanged pages and the new audio for the regenerated page.
    - [ ] Implement caching/reuse logic for unchanged audio segments during the final concatenation step.
    - [ ] Refactor and ensure all tests pass.
- [ ] Task: Conductor - User Manual Verification 'Feedback Loop Integration' (Protocol in workflow.md)