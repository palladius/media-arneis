# Implementation Plan: Implement Asynchronous Polling and State-Based Orchestration

## Phase 1: Async Infrastructure (Python)
- [ ] Task: Update `util/generate_video.py` with `--start-only` flag.
- [ ] Task: Update `util/generate_video.py` with `--check-status <OP_NAME>` mode.
- [ ] Task: Update `util/generate_music.py` with similar async capabilities.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: State & Ruby Generators
- [ ] Task: Update `Arneis::Generator::Base` to handle async return values.
- [ ] Task: Update `Arneis::Generator::Veo` to capture and return `operation_id`.
- [ ] Task: Update `.state.yaml` serialization to store `operation_id`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Orchestration & Polling
- [ ] Task: Enhance `Arneis::VideoProject` to check for existing `polling` operations on `resume`.
- [ ] Task: Implement the status-emoji for `polling` (🔵).
- [ ] Task: Ensure `Orchestrator` can skip or wait based on async status.
- [ ] Task: Final end-to-end verification with `just arnectl apply`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
