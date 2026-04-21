# Implementation Plan: CLI Improvements - ARNEIS_FOLDER and --media-folder

## Phase 1: Thor Configuration & Environment Variable
- [x] Task: Update `Arneis::Cli` (Thor) to include a global option `-f / --media-folder`.
- [x] Task: Implement a helper method in `Arneis::Cli` to resolve the final media folder from flags, arguments, or environment variables.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Refactor Commands to Use Resolved Folder
- [x] Task: Update the `status`, `resume`, `apply`, `check-fake-media`, and `cleanup` commands to use the resolved folder.
- [x] Task: Ensure that if no folder is found in any source, the command fails with a helpful error message.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Verification & Polish
- [x] Task: Write unit tests in `spec/arneis/cli_folder_resolution_spec.rb` to verify the precedence order.
- [x] Task: Verify the new functionality manually with various combinations of environment variables, flags, and arguments.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
