# Implementation Plan: YAML Template Inheritance and Validation

## Phase 1: Foundation & Dependencies
- [ ] Task: Add `dry-validation` and `deep_merge` to Gemfile and install.
- [ ] Task: Create `Arneis::Schema` module to house validation logic.
- [ ] Task: Define the base K8s-compliant schema (apiVersion, kind, metadata).
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Template Validation & K8s Schema
- [ ] Task: Define `TemplateSchema` for core templates ensuring `apiVersion: media-arneis.palladius.it/v1`.
- [ ] Task: Write Tests for `Arneis::Schema.validate_template`.
- [ ] Task: Implement `Arneis::Schema.validate_template` to check all files in `data/templates/`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Hydration & Instance Validation
- [ ] Task: Define `SampleSchema` which validates K8s fields and template linking.
- [ ] Task: Write Tests for `Arneis::Hydrator.hydrate` (Deep Merge and K8s metadata check).
- [ ] Task: Implement `Arneis::Hydrator.hydrate` to merge template defaults with sample values.
- [ ] Task: Write Tests for `Arneis::Schema.validate_instance`.
- [ ] Task: Implement `Arneis::Schema.validate_instance` with meaningful error messages for human/LLM.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: CLI Integration & Hard Fail
- [ ] Task: Update `Arneis::VideoProject` to trigger hydration and validation during initialization.
- [ ] Task: Implement Hard Fail logic with color-coded, detailed error reporting.
- [ ] Task: Verify that `just test` and `arnectl apply` correctly enforce new K8s-compliant rules.
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
