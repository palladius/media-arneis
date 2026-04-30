# Implementation Plan: CharacterImage Generation

## Phase 1: Foundation & Single Character Support
- [ ] Task: Define the `CharacterImage` Template
    - [ ] Create `data/templates/CharacterImage.yaml` defining the schema.
    - [ ] Create an initial sample at `data/samples/CharacterImage/riccardo_sake.yaml`.
- [ ] Task: Implement the `CharacterImage` Domain Model
    - [ ] Write failing tests in `spec/arneis/character_image_spec.rb` for model instantiation and character resolution.
    - [ ] Implement `Arneis::CharacterImage` in `lib/arneis/character_image.rb`.
    - [ ] Ensure it correctly pulls physical traits from `data/characters/`.
- [ ] Task: Orchestrate Single Character Generation
    - [ ] Write tests to verify that `Orchestrator` can process a `CharacterImage`.
    - [ ] Update `Arneis::Orchestrator` to handle the new task type if necessary.
    - [ ] Verify e2e generation of a single-character image.
- [ ] Task: Conductor - User Manual Verification 'Foundation & Single Character Support' (Protocol in workflow.md)

## Phase 2: Evaluation & Quality Gate
- [ ] Task: Implement Gemini Vision Resemblance Evaluator
    - [ ] Write failing tests for a new `Arneis::Evaluator` component that uses vision.
    - [ ] Implement `lib/arneis/evaluator/vision_resemblance.rb` to score images against character traits.
- [ ] Task: Integrate Evaluation into the Task Lifecycle
    - [ ] Update `CharacterImage` to automatically append an evaluation task after image generation.
    - [ ] Implement the "Strict Validation" logic: mark the parent task as failed if the score is below the threshold.
- [ ] Task: Conductor - User Manual Verification 'Evaluation & Quality Gate' (Protocol in workflow.md)

## Phase 3: Multi-Character & CLI Integration
- [ ] Task: Extend to Multi-Character Scenes
    - [ ] Update prompt construction to handle multiple character descriptions in one frame.
    - [ ] Update the evaluator to validate presence and resemblance of all requested characters.
- [ ] Task: Implement the `arnectl generate` Command
    - [ ] Update `Arneis::CLI` to support `generate <ClassName>`.
    - [ ] Implement the dynamic object creation logic using `--characters` and `--prompt` flags.
    - [ ] Add regression tests to ensure existing CLI commands (e.g., `arnectl apply`) remain unaffected.
- [ ] Task: Conductor - User Manual Verification 'Multi-Character & CLI Integration' (Protocol in workflow.md)
