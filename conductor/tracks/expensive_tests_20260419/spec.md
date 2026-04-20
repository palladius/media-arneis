# Track Specification: Implement expensive, end-to-end LLM integration tests

## Track Overview
This track implements a dedicated test suite (`just-llm-tests`) designed to verify the full end-to-end generation and validation path for all AI-driven media types. These tests involve real API calls and monetary costs.

## User Stories
- **As a Developer,** I want a single command that proves the entire stack (from Python scripts to Ruby validation) is working correctly with the current live models.
- **As an SRE,** I want to detect breaking changes in third-party AI APIs before they affect production runs.

## Functional Requirements
- **Integrated Media Tests:**
  - `Arneis::Test::VideoGen`: Triggers a real 5s Veo video.
  - `Arneis::Test::ImageGen`: Triggers a real Imagen 3 generation and an image edit.
  - `Arneis::Test::AudioGen`: Triggers a real Lyria 30s clip and a Chirp narration.
- **Verification Logic:**
  - Every test must use `Arneis::Validator` to confirm the binary integrity of the output.
  - Every test must use `Arneis::Evaluator` to confirm the quality/relevance score is > 7/10.
- **CLI Expiry:**
  - Implement `just-llm-tests` in the `Justfile`.
  - Ensure these tests are explicitly OPT-IN to avoid accidental spending during normal TDD.

## Acceptance Criteria
- [ ] `just just-llm-tests` successfully produces and verifies real MP4, PNG, and WAV files.
- [ ] Stats correctly reflect the total cost of the test run (~$5.00+).
- [ ] A summary report is generated showing model response times and quality scores.

## Out of Scope
- Integration with CI/CD (these tests remain local-only for now due to cost).
- Automatic retries on 429 errors during testing (we want to see the limits).
