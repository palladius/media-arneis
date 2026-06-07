# Specification: Clean up Testing Semantics & Implement LLM-as-Judge Integration Tests

## Overview
Clean up testing semantics in Media Harness by separating quick unit tests from slow integration/eval tests.
- Unit tests must be fast and mock all external API/LLM calls.
- Integration tests will call real APIs to generate small media atoms (images, audio, video) and evaluate them using Gemini as a semantic judge.

## Functional Requirements
1. **Directory Structure**:
   - Fast unit tests: `spec/arneis/` (or `spec/unit/`)
   - LLM-as-judge integration tests: `spec/integration/`
   - E2E tests: `spec/e2e/`
2. **Justfile Targets**:
   - `just test`: Runs quick unit tests by calling `just unit-test`.
   - `just unit-test`: Runs fast unit tests (no LLM/expensive calls).
   - `just integration-test`: Runs tests under `spec/integration/` (uses real LLM-as-judge to evaluate generated outputs).
   - `just e2e-test`: Runs full E2E pipeline tests.
   - Cleanup/streamline redundant test targets like `long-tests` or `test-expensive`.
3. **LLM-as-Judge Helper**:
   - Implement custom RSpec matchers or helper methods in `spec/spec_helper.rb` or `spec/support/` that call Gemini to evaluate the quality/validity of generated media assets.
4. **Documentation**:
   - Add a clear 2-3 line section to `GEMINI.md` explaining the strict boundary between unit tests (fast, mock-only) and integration/E2E tests (real LLM, judge-evaluated).

## Acceptance Criteria
- `just test` runs unit tests and completes in under 5 seconds.
- `just integration-test` successfully generates media assets (image, music, video) and uses LLM-as-judge to evaluate them.
- `GEMINI.md` is updated.
