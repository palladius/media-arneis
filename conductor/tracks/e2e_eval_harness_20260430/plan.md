# Implementation Plan: E2E Evaluation & Verification

## Phase 1: Foundation & CLI Integration [checkpoint: 09f883b]
- [x] Task: Extend CLI with --verify flag [x] 601f456
- [x] Task: Create E2E Test Fixtures [x] dae815a
- [x] Task: Implement Basic Asset Validator [x] dae815a
- [x] Task: Conductor - User Manual Verification 'Foundation & CLI Integration' (Protocol in workflow.md) [x] dae815a

## Phase 2: Tiered Evaluation Harness
- [x] Task: Implement JSON Schema & Logic Evaluator (Tier 1) [x] dae815a
    - [x] Write failing tests for validating `KidsStory` and `VideoProject` JSON outputs.
    - [x] Implement `Arneis::Evaluator.check_json(content, schema)` using Gemini 2.5 Flash.
- [x] Task: Implement Multimodal Intent Evaluator (Tier 2) [x] dae815a
    - [x] Write failing tests for matching image/video output against task prompts.
    - [x] Implement `Arneis::Evaluator.check_multimodal(artifact_path, intent_prompt)` using Gemini 3 Pro.
- [x] Task: Integrate Evaluators into Orchestrator [x] dae815a
    - [x] Update `lib/arneis/orchestrator.rb` to run evaluators when `--verify` is set.
    - [x] Implement the "Hard Fail" logic to stop execution on evaluation failure.
- [x] Task: Conductor - User Manual Verification 'Tiered Evaluation Harness' (Protocol in workflow.md) [x] dae815a

## Phase 3: Observability & Final E2E Validation
- [x] Task: Persist Evaluation Metadata [x] dae815a
    - [x] Update task metadata to store evaluation scores, feedback, and model reasoning.
    - [x] Ensure evaluation results are visible in the `arnectl status` output.
- [x] Task: Full E2E Harness Test Drive [x] dc332a1
    - [x] Run a complete `KidsStory` generation with `--verify` and confirm success.
    - [x] Run a `VideoProject` generation with a deliberate mismatch and confirm "Hard Fail" behavior.
- [ ] Task: Conductor - User Manual Verification 'Observability & Final E2E Validation' (Protocol in workflow.md)
    - [x] Initial implementation merged to `main`.
    - [ ] Perform follow-up E2E runs on production-grade YAMLs.
