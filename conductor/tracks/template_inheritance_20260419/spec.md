# Track Specification: YAML Template Inheritance and Validation

## Overview
This track implements a robust validation and inheritance mechanism for YAML data files, following Kubernetes-compliant patterns. Samples in subfolders of `data/samples/` (e.g., `VideoProject/`, `KidsStory/`) will inherit from base templates in `data/templates/` using a "hydration" (deep merge) strategy. Structural integrity will be enforced using `dry-validation`.

## Functional Requirements
1. **Kubernetes-Compliant Structure:** All YAML files (templates and samples) MUST include `apiVersion`, `kind`, and `metadata` fields.
2. **API Versioning:** The `apiVersion` field SHOULD point to the project's logic versioning (e.g., `media-arneis.palladius.it/v1`).
3. **Explicit Template Linking:** Every sample YAML MUST include a `template` field within its `metadata` (or spec) specifying the base template name.
4. **Template Validation:** Implement `TemplateTest` to ensure all files in `data/templates/` are valid according to the defined schema.
5. **Instance Validation:** Implement `InstanceTest` for all samples. Validation MUST confirm the presence and correct type of mandatory fields inherited from the template.
6. **Hydration Mechanism:** Samples will be "hydrated" by deep-merging template defaults with sample-specific overrides.
7. **Meaningful Error Reporting:** Validation failures MUST result in a Hard Fail with messages optimized for both humans and LLMs.

## Acceptance Criteria
- [ ] `just test` includes validation for all templates and samples.
- [ ] Samples without correct `apiVersion`, `kind`, or `template` cause a Hard Fail.
- [ ] Final object used in orchestration contains merged values from both template and sample.

## Out of Scope
- Implementation of the multi-layered inheritance model (e.g., `VideoTemplate` -> `IntermediateTemplate` -> `Object`) is deferred to a future track.
