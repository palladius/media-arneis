# Track Specification: Implement Robust Artifact Validation and Metadata Extraction

## Track Overview
This track addresses the issue of "lying" artifacts (e.g., text files saved with `.mp4` extensions) by implementing a mandatory post-creation validation hook. Every asset generated must pass a structural integrity check before being marked as successful.

## User Stories
- **As a Developer,** I want to be 100% certain that an `.mp4` file is actually a video file and not a text error dump.
- **As a System,** I want to automatically flag and rename invalid artifacts to prevent them from contaminating the final project assembly.

## Functional Requirements
- **Post-Creation Hook (`after_creation`):**
  - Triggered immediately after any generator (Veo, Imagen, Lyria, Montage) writes a file.
  - Executes the system `file` command on the new artifact.
  - Matches the output against expected magic numbers/strings (e.g., `ISO Media`, `MPEG`, `PNG`).
- **Validation Logic:**
  - If VALID:
    - Update the asset's `.asset.json` with physical metadata: `file_size`, `file_type`, and (if possible) `duration`.
    - Proceed to the EVAL phase.
  - If INVALID:
    - Mark the status as `failed` in `.state.yaml`.
    - Rename the file to `[filename].[ext].NOT_GOOD`.
    - Log the specific `file` command output in the error report.
- **Project-Level Integration:**
  - The final montage task MUST verify that all input files are VALID and not `.NOT_GOOD`.

## Acceptance Criteria
- [ ] A mock text file saved as `.mp4` is automatically renamed to `.mp4.NOT_GOOD`.
- [ ] The `.asset.json` for a real video contains the correct `file_size` and `file_type`.
- [ ] The `status` command correctly reflects the `.NOT_GOOD` state with an appropriate emoji.
