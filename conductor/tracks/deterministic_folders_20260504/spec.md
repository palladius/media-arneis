# Specification: Deterministic Output Folders & PID Locking

## Overview
Implement a deterministic naming convention for output folders to avoid timestamped directories when not explicitly requested. Additionally, implement a PID-based locking mechanism (`.arneis.lock`) within the output folder to prevent concurrent `arnectl` processes from interfering with the same project directory.

## Functional Requirements

### 1. Deterministic Naming
- Default output path (when not specified): `out/<kind>_<basename>/`
- Format: Lower snake case (e.g., `out/character_image_ale_seby_super_ninja/`)
- This replaces the current `out/YYYYMMDD_HHMMSS_...` default.

### 2. PID Locking Mechanism
- **File**: `.arneis.lock` created in the root of the output folder.
- **Content**: Must contain the PID of the process and the full command (ARGV) for visual confirmation.
- **Lifecycle**: Created during project initialization; removed upon successful completion (or left as a safeguard if interrupted).

### 3. Collision & Lock Handling
- **Active Lock**: If a lock exists and the PID is still running (verified via `Process.kill(0, pid)`), `arnectl` must exit with a clear message: "Sorry, I can't; another process [PID] is already working on this folder: [COMMAND]".
- **Stale Lock**: If the PID is no longer running, `arnectl` should inform the user: "A stale lock file was found (PID [PID] is no longer active). Please remove '.arneis.lock' manually or use --force to continue."
- **Safe Overwrite**: If the folder exists but no lock is present, allow safe re-initialization.

### 4. Overwrite Flag
- Use the existing `--force` flag to bypass lock checks and overwrite the target directory.

## Non-Functional Requirements
- **Informative Output**: Provide high-signal feedback to the developer (Riccardo) about why a run was blocked.
- **Robustness**: Ensure PID checking is reliable on Linux.

## Acceptance Criteria
- [ ] `arnectl apply <yaml>` creates a folder like `out/character_image_.../`.
- [ ] Concurrent runs on the same YAML result in the second run exiting gracefully with the "active lock" error.
- [ ] Killing a process leaves the lock file; a subsequent run detects it as "stale".
- [ ] Using `--force` successfully ignores any active or stale lock.

## Out of Scope
- Distributed locking for cloud storage.
- Automatic deletion of stale locks without user intervention.
