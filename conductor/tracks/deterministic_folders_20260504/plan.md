# Implementation Plan: Deterministic Output Folders & PID Locking

## Phase 1: Deterministic Output Naming
Implement the new folder naming convention based on project Kind and YAML basename.

- [ ] Task: TDD - Update default output path logic in `Arneis::Cli#apply`
    - [ ] Write tests in `spec/arneis/cli_apply_spec.rb` (or new file) for the `out/kind_basename/` pattern
    - [ ] Update `lib/arneis/cli.rb` to implement the deterministic naming
- [ ] Task: TDD - Update `Arneis::Cli#generate` for consistency
    - [ ] Ensure ad-hoc generations also follow the same naming logic
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Deterministic Output Naming' (Protocol in workflow.md)

## Phase 2: PID Locking Mechanism
Implement the lock file creation and metadata storage.

- [ ] Task: TDD - Implement `Arneis::LockFile` helper
    - [ ] Create `lib/arneis/lock_file.rb`
    - [ ] Write tests for lock creation, reading PID/ARGV, and deletion
- [ ] Task: TDD - Integrate locking into Project Initialization
    - [ ] Update `lib/arneis/base_project.rb` (or common initialization point) to create `.arneis.lock`
    - [ ] Ensure lock is removed on successful completion in `Arneis::Cli`
- [ ] Task: Conductor - User Manual Verification 'Phase 2: PID Locking Mechanism' (Protocol in workflow.md)

## Phase 3: Collision Handling & Force
Implement the logic to detect active/stale locks and handle the `--force` flag.

- [ ] Task: TDD - Implement Active/Stale PID detection
    - [ ] Add `active?` check to `Arneis::LockFile` using `Process.kill(0, pid)`
    - [ ] Write tests for active vs. stale detection
- [ ] Task: TDD - Block concurrent runs in `Arneis::Cli#apply`
    - [ ] Implement the logic to stop execution with high-signal error message
    - [ ] Add support for `--force` to bypass the lock
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Collision Handling & Force' (Protocol in workflow.md)
