# Specification: KidsStory Multilingual Audio Generation

## Overview
The `KidsStory` media generation process will be enhanced to automatically generate audio narrations in multiple languages upon completion of the story text. The process is driven by a `story_audio` array configured in the story's YAML definition (defaulting to `[en, it]`). The initial implementation will focus on enabling English (`en`).

## Functional Requirements
1. **Audio Trigger:** The system will check the `story_audio` array in the YAML. If present, it will initiate the audio generation pipeline for each specified language code.
2. **Translation & Generation Strategy:** The system must translate the story text and generate the audio paragraph-by-paragraph (or page-by-page) rather than processing the entire story at once.
3. **TTS Engine:** Utilize Google's Chirp 2 model for text-to-speech generation.
4. **YAML Configuration:** The configuration will be a simple array of language codes (e.g., `story_audio: [en, it]`).
5. **Dependency & File Management (CRITICAL):**
   - Audio files for individual pages/paragraphs must be stored within their respective page directories (e.g., `page01/audio_en.wav`).
   - The final audio output for the entire story in a specific language must be a deterministic concatenation of the individual page audio files (e.g., `page01/audio_en.wav` + `page02/audio_en.wav` -> `final_story_en.wav`).
   - **Feedback Loop Integration:** The orchestration must handle partial regenerations correctly. If a specific page (e.g., "page 2") is regenerated, the system must:
     1. Regenerate the text for page 2.
     2. Translate and generate the new audio for page 2 (`page02/audio_en.wav`).
     3. Re-concatenate the final story audio using the preserved audio from page 1 and page 3, alongside the new audio from page 2.

## Acceptance Criteria
- A `KidsStory` object with `story_audio: [en]` successfully generates paragraph-level text and audio files using Chirp 2.
- Individual page audio files are correctly stored in their respective `pageXX/` directories.
- The final story audio is deterministically built by concatenating the individual page audio files.
- Modifying or regenerating a single page updates only that page's text and audio, and accurately rebuilds the final concatenated audio without regenerating unchanged pages.