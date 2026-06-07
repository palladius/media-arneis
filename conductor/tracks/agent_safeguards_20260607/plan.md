# Plan: Agent Safeguards - Spec Failure Circuit Breaker & Context Warnings

## Phase 1: Spec Run History & Circuit Breaker
- [ ] Task: Write failing unit tests for spec history tracking and circuit breaker
    - [ ] Create `spec/arneis/spec_runner_safeguard_spec.rb`.
    - [ ] Test that running the same spec 3 times consecutively with failures writes to history and raises a halt error.
- [ ] Task: Implement spec history tracking and halting logic
    - [ ] Implement `Arneis::SpecRunnerSafeguard` tracking runs in `tmp/.spec_history.json`.
    - [ ] Integrate this safeguard into the CLI / test helper so it intercepts test runs.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Spec Run History & Circuit Breaker' (Protocol in workflow.md)

## Phase 2: Context Size Monitor & CLI Warning
- [ ] Task: Write unit tests for context size monitoring
    - [ ] Test reading of transcript file and steps count.
    - [ ] Test that a warning is output to stdout when steps count > 1000.
- [ ] Task: Implement context step monitoring and CLI alert
    - [ ] Add helper to locate the current conversation transcript under `~/.gemini/antigravity-cli/brain/`.
    - [ ] Print a colored warning banner in `arnectl` CLI on startup/runs if steps count exceeds 1000.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Context Size Monitor & CLI Warning' (Protocol in workflow.md)

## Phase 3: Auth Resolution & Documentation
- [ ] Task: Document emergency auth resolution rules
    - [ ] Add strict instructions to `GEMINI.md` about halting on oauth permission errors rather than retrying.
- [ ] Task: Verify the entire safeguards suite
    - [ ] Run `just test` and ensure all unit tests pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Auth Resolution & Documentation' (Protocol in workflow.md)
