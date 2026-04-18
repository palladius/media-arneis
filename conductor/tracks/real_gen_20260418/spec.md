# Track Specification: Integrate Google AI Models for real media generation

## Track Overview
This track focuses on replacing the mock generators with actual implementations that call Google's AI models. We will use the `ruby_llm` gem and other relevant tools/APIs to generate text, images, video, and audio.

## User Stories
- **As a Media Creator,** I want `arnectl apply` to generate real media files instead of mocks.
- **As a Creative Lead,** I want to use my `GEMINI_API_KEY` to power the generation process.

## Functional Requirements
- **Gemini Integration (Text & Evals):**
  - Implement `Arneis::Generator::Gemini` for text generation.
  - Use Gemini 1.5 Flash for automated media evaluations (Evals).
- **Veo Integration (Video):**
  - Implement `Arneis::Generator::Veo` for high-quality video generation.
- **Lyria/Chirp Integration (Audio):**
  - Implement `Arneis::Generator::Lyria` for music.
  - Implement `Arneis::Generator::Chirp` or Gemini TTS for narration.
- **Configuration:**
  - Load `GEMINI_API_KEY` and other credentials from the environment (`.env`).
- **Resource Tracking:**
  - Track actual token usage and latency from API responses.

## Acceptance Criteria
- [ ] `arnectl apply rubycon_pitch.yaml` successfully generates at least one real media artifact (e.g., text or image) using a Google model.
- [ ] API keys are correctly pulled from the environment.
- [ ] Token usage and costs are reported in `arnectl stats`.
