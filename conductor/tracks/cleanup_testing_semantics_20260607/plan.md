# Plan: Clean up Testing Semantics & Implement LLM-as-Judge Integration Tests

## Phase 1: Fast Unit Tests Optimization & Justfile Target Streamlining [checkpoint: 24ae768]
- [x] Task: Streamline Justfile test targets [f61fc7a]
    - [x] Define `unit-test` target running RSpec with tag `~expensive` and excluding `spec/integration/` and `spec/e2e/`.
    - [x] Point `test` target to `unit-test`.
    - [x] Define `integration-test` target running RSpec on `spec/integration/`.
    - [x] Define `e2e-test` target running RSpec on `spec/e2e/`.
    - [x] Align or remove redundant targets (`long-tests`, `test-expensive`).
- [x] Task: Ensure all unit tests are mocked and fast [6d96454]
    - [x] Identify any unit tests in `spec/arneis/` executing real calls or taking too long.
    - [x] Refactor or add mocks to keep unit test suite running in <5s.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Fast Unit Tests Optimization & Justfile Target Streamlining' (Protocol in workflow.md)


## Phase 2: LLM-as-Judge & Semantic Assertion Framework
- [x] Task: Create LLM-as-Judge helper/matcher [6bed687]
    - [x] Create `spec/support/llm_judge_helper.rb` (included in `spec_helper.rb`).
    - [x] Implement a helper using Gemini to evaluate generated media assets.
    - [x] Implement a custom RSpec matcher `meet_media_criteria` that leverages this helper.
- [x] Task: Create integration tests under spec/integration/ [6bed687]
    - [x] Create `spec/integration/media_generation_spec.rb`.
    - [x] Add integration test for Imagen (image generation) checking generated output via LLM-as-judge.
    - [x] Add integration test for Lyria (music generation) checking generated output via LLM-as-judge.
    - [x] Add integration test for Veo (video generation) checking generated output via LLM-as-judge.
- [~] Task: Conductor - User Manual Verification 'Phase 2: LLM-as-Judge & Semantic Assertion Framework' (Protocol in workflow.md)

## Phase 3: Documentation & Verification
- [ ] Task: Update GEMINI.md and verify suite
    - [ ] Add a 2-3 line section to `GEMINI.md` explaining the strict testing semantics.
    - [ ] Run `just test` to verify unit tests run fast (<5s).
    - [ ] Run `just integration-test` to verify LLM-as-judge and real generations.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Documentation & Verification' (Protocol in workflow.md)
