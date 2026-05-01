# Implementation Plan: E2E Evaluation & Verification

## Phase 1: Foundation & CLI Integration
- [ ] Task: Extend CLI with `--verify` flag
    - [ ] Update `lib/arneis/cli.rb` to accept the `--verify` boolean flag.
    - [ ] Pass the flag through to the `Orchestrator` and `Planner`.
- [ ] Task: Create E2E Test Fixtures
    - [ ] Create a "corrupt" sample in `spec/fixtures/invalid_story.json` to test detection logic.
    - [ ] Set up an RSpec suite in `spec/arneis/e2e_evaluator_spec.rb`.
- [ ] Task: Implement Basic Asset Validator
    - [ ] Write failing tests to verify file existence for a completed task.
    - [ ] Implement `Arneis::Validator.verify_assets(task)` in `lib/arneis/validator.rb`.
- [ ] Task: Conductor - User Manual Verification 'Foundation & CLI Integration' (Protocol in workflow.md)

## Phase 2: Tiered Evaluation Harness
- [ ] Task: Implement JSON Schema & Logic Evaluator (Tier 1)
    - [ ] Write failing tests for validating `KidsStory` and `VideoProject` JSON outputs.
    - [ ] Implement `Arneis::Evaluator.check_json(content, schema)` using Gemini 2.5 Flash.
- [ ] Task: Implement Multimodal Intent Evaluator (Tier 2)
    - [ ] Write failing tests for matching image/video output against task prompts.
    - [ ] Implement `Arneis::Evaluator.check_multimodal(artifact_path, intent_prompt)` using Gemini 3 Pro.
- [ ] Task: Integrate Evaluators into Orchestrator
    - [ ] Update `lib/arneis/orchestrator.rb` to run evaluators when `--verify` is set.
    - [ ] Implement the "Hard Fail" logic to stop execution on evaluation failure.
- [ ] Task: Conductor - User Manual Verification 'Tiered Evaluation Harness' (Protocol in workflow.md)

## Phase 3: Observability & Final E2E Validation
- [ ] Task: Persist Evaluation Metadata
    - [ ] Update task metadata to store evaluation scores, feedback, and model reasoning.
    - [ ] Ensure evaluation results are visible in the `arnectl status` output.
- [ ] Task: Full E2E Harness Test Drive
    - [ ] Run a complete `KidsStory` generation with `--verify` and confirm success.
    - [ ] Run a `VideoProject` generation with a deliberate mismatch and confirm "Hard Fail" behavior.
- [ ] Task: Conductor - User Manual Verification 'Observability & Final E2E Validation' (Protocol in workflow.md)
