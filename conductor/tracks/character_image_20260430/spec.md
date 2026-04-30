# Specification: CharacterImage Generation Track

## Overview
Implement a new Template Class `CharacterImage` designed to generate images featuring one or more registered characters in specific scenarios. This track includes direct CLI support for ad-hoc generation and an automated evaluation loop using Gemini Vision to ensure character consistency and resemblance.

## Functional Requirements

### 1. Template Definition
- Create a new template file `data/templates/CharacterImage.yaml`.
- Define the schema for `CharacterImage`, which includes:
    - `characters`: A list of character IDs (validated against `data/characters/`).
    - `prompt`: The descriptive text for the scene.
    - `negative_prompt`: (Optional) Standard negative prompts for image quality.

### 2. CLI Integration
- Implement `arnectl generate CharacterImage --characters <id1,id2> --prompt "<text>"`.
- The CLI should dynamically instantiate a `CharacterImage` object, resolve character metadata, and trigger the orchestration.
- Support both ad-hoc CLI generation and standard YAML-based generation via `data/samples/CharacterImage/*.yaml`.

### 3. Generation Logic
- Leverage the existing `Generator::Imagen` (Nano Banana) for image creation.
- Ensure character descriptions from `data/characters/` are injected into the final prompt to maintain visual consistency.

### 4. Evaluation & Quality Gate
- **Gemini Vision Scoring:** Post-generation, use Gemini Vision to analyze the output image.
- **Resemblance Check:** Compare the image against the physical traits defined in the character's registry.
- **Strict Validation:** The generation task MUST be marked as failed if the resemblance score falls below a defined threshold (e.g., 7/10).
- **Soft Validation:** Log the score and feedback for all generations, even if they pass.

## Non-Functional Requirements
- **Extensibility:** Start with single-character support and ensure the architecture allows for 2+ characters in the same scene.
- **Traceability:** Evaluation results should be stored in the task's artifact metadata.

## Acceptance Criteria
- [ ] `arnectl generate CharacterImage --characters riccardo --prompt "pours a sake"` successfully triggers generation.
- [ ] The system validates that `riccardo` exists in the character registry.
- [ ] An evaluation step follows the generation, visible in the `arnectl status` output.
- [ ] A poor-resemblance image (simulated or real) correctly triggers a task failure.
- [ ] Multi-character support (e.g., `riccardo,yukihiro`) works in a single frame.
