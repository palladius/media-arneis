# Plan: Agent Safeguards - Spec Failure Circuit Breaker & Context Warnings

## Phase 1: Spec Run History & Circuit Breaker [checkpoint: 4ebf4bb]
- [x] Task: Write failing unit tests for spec history tracking and circuit breaker [8238d37]
    - [x] Create `spec/arneis/spec_runner_safeguard_spec.rb`.
    - [x] Test that running the same spec 3 times consecutively with failures writes to history and raises a halt error.
- [x] Task: Implement spec history tracking and halting logic [8238d37]
    - [x] Implement `Arneis::SpecRunnerSafeguard` tracking runs in `tmp/.spec_history.json`.
    - [x] Integrate this safeguard into the CLI / test helper so it intercepts test runs.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Spec Run History & Circuit Breaker' (Protocol in workflow.md) [4ebf4bb]

## Phase 2: Context Size Monitor & CLI Warning
- [x] Task: Write unit tests for context size monitoring [1df9fde]
    - [x] Test reading of transcript file and steps count.
    - [x] Test that a warning is output to stdout when steps count > 1000.
- [x] Task: Implement context step monitoring and CLI alert [1df9fde]
    - [x] Add helper to locate the current conversation transcript under `~/.gemini/antigravity-cli/brain/`.
    - [x] Print a colored warning banner in `arnectl` CLI on startup/runs if steps count exceeds 1000.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Context Size Monitor & CLI Warning' (Protocol in workflow.md)

## Phase 3: Auth Resolution & Documentation
- [ ] Task: Document emergency auth resolution rules
    - [ ] Add strict instructions to `GEMINI.md` about halting on oauth permission errors rather than retrying.
- [ ] Task: Verify the entire safeguards suite
    - [ ] Run `just test` and ensure all unit tests pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Auth Resolution & Documentation' (Protocol in workflow.md)
