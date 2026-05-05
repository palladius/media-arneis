# Specification: E2E Testing & Mock Abolition

## 1. Overview
This epic will introduce a robust end-to-end (E2E) testing framework for the `arneis` system and eliminate the practice of generating "mock" files when a generation task fails. The new philosophy is to fail fast and loudly, rather than produce misleading or incomplete results.

## 2. Core Requirements

### 2.1. Abolition of Mock Files
- **New Configuration:** A new environment variable, `ARNEIS_NO_MOCK=true`, will be introduced.
- **Fatal Errors:** When `ARNEIS_NO_MOCK` is set to `true`, any media generator (`Imagen`, `Chirp`, `Lyria`, `Veo`, etc.) that fails must raise a fatal error instead of creating a `.mock` file.
- **Orchestration Halt:** This fatal error should halt the processing of the specific task, marking it as `failed` in the `.state.yaml`, allowing the user to see the exact point of failure.
- **Default Behavior:** When `ARNEIS_NO_MOCK` is not set or is `false`, the system will retain the current behavior (though this may be phased out later). For the purpose of the E2E tests, it must be active.

### 2.2. End-to-End Test for `KidsStory`
- **New Test Suite:** A new, independent RSpec suite will be created at `spec/e2e/kids_story_e2e_spec.rb`.
- **Real AI Calls:** This test will make real, live calls to the Gemini, Chirp, and Imagen APIs. It will be tagged as an "expensive" test.
- **Process:** The test will execute `bundle exec bin/arnectl apply` on a sample `KidsStory` YAML.
- **Validation:**
    - It must assert that all expected **real** media files are created (e.g., `illustration.png`, `audio_it.wav`, `audio_en.wav`, `final_story_it.wav`, `STORY.md`).
    - It must parse the `.asset.json` files to confirm that evaluations (character consistency, audio intelligibility) were executed.
    - It must verify that no `.mock` files were created.

### 2.3. End-to-End Test for `VideoProject`
- **New Test Suite:** A new RSpec suite will be created at `spec/e2e/video_project_e2e_spec.rb`.
- **Real AI Calls:** This test will also be tagged as "expensive" and make live API calls.
- **Process:** The test will execute `bundle exec bin/arnectl apply` on a sample `VideoProject` YAML.
- **Validation:**
    - It must assert that all expected **real** video and audio files are created (e.g., `scene_1.mp4`, `background_music.wav`, `final_montage.mp4`).
    - It must verify that no `.mock` files were created.
