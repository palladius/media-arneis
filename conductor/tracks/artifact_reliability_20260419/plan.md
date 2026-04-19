# Implementation Plan: Implement Robust Artifact Validation and Metadata Extraction

## Phase 1: Core Hook Logic
- [ ] Task: Enhance `Arneis::Validator` with a `validate_and_rename!` method.
- [ ] Task: Implement file renaming to `.NOT_GOOD` for invalid types.
- [ ] Task: Implement metadata extraction (size, type) using `File.size` and `file` command.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Generator Integration
- [ ] Task: Update `Arneis::Generator::Base` to support the `after_creation` hook.
- [ ] Task: Integrate the hook into Veo, Imagen, and Lyria generators.
- [ ] Task: Ensure `VideoProject#process` handles the `.NOT_GOOD` state gracefully.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Visuals & Verification
- [ ] Task: Add a specific emoji/indicator in `status` for `.NOT_GOOD` artifacts.
- [ ] Task: Update `.asset.json` schema to include the new metadata fields.
- [ ] Task: Verify the entire flow by forcing a mock failure and checking the rename.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
