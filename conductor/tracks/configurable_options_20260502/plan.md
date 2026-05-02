# Implementation Plan: Configurable Post-Creation Actions

## Phase 1: Core Configuration Logic
Implement the logic to resolve the status of "eval" and "open" based on flags, environment variables, and defaults.

- [x] Task: Create unit tests for Configuration Resolution e653eb9
    - [x] Define tests in `spec/arneis/config_spec.rb`.
    - [x] Test precedence: Flag > ENV > Default.
- [x] Task: Implement Configuration Resolution logic e653eb9
    - [x] Update `lib/arneis/config.rb` to handle the new settings.
    - [x] Ensure `ENV` variables are read correctly.
- [ ] Task: Conductor - User Manual Verification 'Core Configuration Logic' (Protocol in workflow.md)

## Phase 2: CLI Integration
Integrate the new flags into the `arnectl` CLI and update the help documentation.

- [ ] Task: Create tests for CLI flag handling
    - [ ] Add tests to `spec/arneis/cli_spec.rb`.
    - [ ] Verify that `--no-eval` and `--no-open` are correctly parsed.
- [ ] Task: Implement CLI flag handling in `Arneis::CLI`
    - [ ] Add `class_option` to the Thor CLI definition in `lib/arneis/cli.rb`.
    - [ ] Pass the resolved configuration to the relevant tasks.
- [ ] Task: Update help text
    - [ ] Ensure `arnectl help` shows the new flags and mentions the environment variables.
- [ ] Task: Conductor - User Manual Verification 'CLI Integration' (Protocol in workflow.md)

## Phase 3: Orchestration Integration
Update the orchestration logic to respect the new configuration settings during media generation.

- [ ] Task: Create tests for Orchestration respect of config
    - [ ] Update `spec/arneis/orchestrator_spec.rb` or task-specific specs.
    - [ ] Verify that `Evaluator` is not called when disabled.
    - [ ] Verify that system "open" is not called when disabled.
- [ ] Task: Implement conditional execution in Orchestrator/Tasks
    - [ ] Wrap evaluation calls in a conditional check.
    - [ ] Wrap "open" calls in a conditional check.
- [ ] Task: Conductor - User Manual Verification 'Orchestration Integration' (Protocol in workflow.md)
