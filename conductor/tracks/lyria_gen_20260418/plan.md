# Implementation Plan: Implement Real Background Music Generation using Lyria

## Phase 1: Infrastructure & Script Setup
- [ ] Task: Identify or create a stable Python script for Lyria generation (similar to `veo_script`).
- [ ] Task: Add `lyria_script` path to `Arneis::Config`.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Real Lyria Generator
- [ ] Task: Implement `Arneis::Generator::Lyria` using the identified script or direct API.
- [ ] Task: Implement LRO polling and GCS handling for Lyria.
- [ ] Task: Verify with a standalone test script.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Orchestration & Final Polish
- [ ] Task: Update `VideoProject` to trigger real Lyria generation.
- [ ] Task: Ensure artifact validation works for the real music files.
- [ ] Task: Verify the full flow with `just arnectl resume`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
