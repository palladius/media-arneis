# Implementation Plan: Implement Robust Artifact Validation and Metadata Extraction

## Phase 1: Core Hook Logic
- [x] Task: Enhance `Arneis::Validator` with a `validate_and_rename!` method. da78481
- [x] Task: Implement file renaming to `.NOT_GOOD` for invalid types. da78481
- [x] Task: Implement metadata extraction (size, type) using `File.size` and `file` command. da78481
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Generator Integration
- [x] Task: Update `Arneis::Generator::Base` to support the `after_creation` hook.
- [x] Task: Integrate the hook into Veo, Imagen, and Lyria generators. (Done in previous turns)
- [x] Task: Ensure `VideoProject#process` handles the `.NOT_GOOD` state gracefully. (Handled by arnectl resume)
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Visuals & Verification
- [x] Task: Add a specific emoji/indicator in `status` for `.NOT_GOOD` artifacts. (Done: 🚫 INVALID)
- [x] Task: Update `.asset.json` schema to include the new metadata fields. da78481
- [x] Task: Verify the entire flow by forcing a mock failure and checking the rename. (Verified manually in KidsStory debug)
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
