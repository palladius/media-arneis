# Specification: KidsStory Multilingual Audio Generation & Eval-Driven Redo

## Overview
The `KidsStory` media generation process will be enhanced to automatically generate audio narrations in multiple languages upon completion of the story text. Additionally, the system will provide an automated way to redo sub-optimal generation tasks based on evaluation scores.

## Functional Requirements
1. **Audio Trigger:** The system will check the `story_audio` array in the YAML. If present, it will initiate the audio generation pipeline for each specified language code (defaulting to `[it, en]`).
2. **Translation & Generation Strategy:** The system must translate the story text and generate the audio paragraph-by-paragraph (or page-by-page) rather than processing the entire story at once.
3. **TTS Engine & Voice Consistency:**
   - Utilize Google's Chirp 2 model for text-to-speech generation.
   - **Voice Consistency:** For each language, a consistent, hardcoded voice will be used for now (e.g., `it-IT-Standard-A` for Italian, `en-US-Standard-B` for English).
4. **YAML Configuration:** The configuration will be a simple array of language codes (e.g., `story_audio: [en, it]`).
5. **Dependency & File Management (CRITICAL):**
   - Audio files for individual pages/paragraphs must be stored within their respective page directories (e.g., `page01/audio_en.wav`).
   - The final audio output for the entire story in a specific language must be a deterministic concatenation of the individual page audio files.
   - **Feedback Loop Integration:** Regeneration of a single page must update only that page's text and audio and rebuild the final concatenated audio.
6. **Evaluation-Driven Invalidation:**
   - **Threshold Monitoring:** In `arnectl status`, if any artifact (image, text, audio) has an evaluation score below a defined threshold (default: 6/10), a notification must be displayed.
   - **Redo Suggestion:** The status output must suggest a command to invalidate and redo sub-optimal jobs, e.g., `arnectl redo --threshold 6`.
   - **Redo Logic:** Implement the logic for `arnectl redo --threshold N` to identify and invalidate artifacts below the specified threshold, allowing the orchestrator to pick them up in the next run.

## Acceptance Criteria
- A `KidsStory` object with `story_audio: [en]` successfully generates paragraph-level text and audio files using a consistent voice.
- `arnectl status` displays a warning and a `redo` command suggestion when evaluations are below 6/10.
- `arnectl redo --threshold 6` successfully invalidates the correct artifacts.
- Modifying or regenerating a single page updates only that page's text and audio, and accurately rebuilds the final concatenated audio.