# Implementation Plan: YAML Template Inheritance and Validation

## Phase 1: Foundation & Dependencies
- [x] Task: Add `dry-validation` and `deep_merge` to Gemfile and install. 174b04f
- [x] Task: Create `Arneis::Schema` module to house validation logic. 69288cb
- [x] Task: Define the base K8s-compliant schema (apiVersion, kind, metadata). 69288cb
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Template Validation & K8s Schema
- [x] Task: Define `TemplateSchema` for core templates ensuring `apiVersion: media-arneis.palladius.it/v1`. 69288cb
- [x] Task: Write Tests for `Arneis::Schema.validate_template`. 69288cb
- [x] Task: Implement `Arneis::Schema.validate_template` to check all files in `data/templates/`. 69288cb
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Hydration & Instance Validation
- [x] Task: Define `SampleSchema` which validates K8s fields and template linking. 69288cb
- [x] Task: Write Tests for `Arneis::Hydrator.hydrate` (Deep Merge and K8s metadata check). 69288cb
- [x] Task: Implement `Arneis::Hydrator.hydrate` to merge template defaults with sample values. 69288cb
- [x] Task: Write Tests for `Arneis::Schema.validate_instance`. 69288cb
- [x] Task: Implement `Arneis::Schema.validate_instance` with meaningful error messages for human/LLM. 69288cb
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: CLI Integration & Hard Fail
- [x] Task: Update `Arneis::VideoProject` to trigger hydration and validation during initialization. f320356
- [ ] Task: Implement Hard Fail logic with color-coded, detailed error reporting.
- [x] Task: Verify that `just test` and `arnectl apply` correctly enforce new K8s-compliant rules. f320356
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
