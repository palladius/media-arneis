# Track Specification: Implement Real Background Music Generation using Lyria

## Track Overview
This track replaces the current Lyria mock/placeholder with a real implementation that calls Google's Lyria model (Pro or Clip) for high-quality music generation. It will include proper integration with Hussain's or similar scripts if needed, or direct API calls with LRO polling.

## User Stories
- **As a Media Creator,** I want to generate real 32-second Italian tarantellas (and other styles) for my video projects.
- **As a Developer,** I want a robust `Lyria` generator that handles polling and GCS output correctly, similar to the Veo generator.

## Functional Requirements
- **Real Lyria Integration:**
  - Implement `Arneis::Generator::Lyria` to call the Pro/Clip models via Vertex AI or the Generative Language API.
  - Handle LRO (Long Running Operations) or blocking calls with appropriate timeouts.
  - Support GCS output if applicable.
- **Orchestration Update:**
  - Ensure the `background_music` task in `VideoProject` is fully functional and not skipped if a real generation is needed.
- **Observability:**
  - Standardized `*.asset.json` receipts for all music assets.

## Acceptance Criteria
- [ ] `arnectl apply` (or `resume`) successfully generates a real `.wav` or `.mp3` file for background music.
- [ ] The generated file passes `Arneis::Validator` with `audio` type.
- [ ] Stats correctly reflect the cost of music generation ($0.10+).
