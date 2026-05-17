# Specification: E2E Evaluation & Verification Track

## Overview
Implement a comprehensive end-to-end (E2E) verification harness for `KidsStory` and `VideoProject` generation. This track adds a `--verify` flag to existing CLI commands to trigger multimodal evaluation, ensuring that the generated artifacts (JSON, text, images, video) strictly align with the user's initial intent.

## Functional Requirements

### 1. CLI Integration
- Extend `arnectl apply` and `arnectl generate` with a `--verify` flag.
- When enabled, the orchestrator MUST trigger a post-generation verification phase for every task.

### 2. Multi-Level Verification (Tiered Evaluation)
- **JSON & Schema Check:** Use Gemini 2.5 Flash to validate that all generated JSON files match the expected schema and contain logically consistent data.
- **Multimodal Intent Matching:** Use Gemini 3 Pro (Vision) for complex media (images/video) to verify that the visual output matches the descriptive prompt.
- **Asset Integrity:** Verify that every file declared in the task's output exists on disk and is not corrupted.

### 3. Workflow Piggybacking
- Inject the verification logic into the `Orchestrator` task lifecycle.
- Implement a "Hard Fail" policy: if any verification step fails, the task status MUST be set to `failed`, and dependent tasks MUST be halted.

### 4. Implementation Environment
- Use `git-worktree` to isolate the development of this harness, as per project guidelines for high-impact orchestration changes.

## Non-Functional Requirements
- **Observability:** Verification results (scores, feedback, model reasoning) must be stored in the task's artifact metadata and visible via `arnectl status`.
- **Performance:** JSON checks should be near-instantaneous; multimodal checks should run in parallel to minimize latency.

## Acceptance Criteria
- [ ] `arnectl generate KidsStory --verify` fails if an image does not match the page text.
- [ ] `arnectl generate VideoProject --verify` fails if the output JSON structure is invalid.
- [ ] All verification logs are accessible in the `out/` directory for the specific project.
- [ ] The harness correctly distinguishes between minor stylistic differences (pass) and intent mismatches (fail).
