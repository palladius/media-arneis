# Implementation Plan - Google Slides Export (feature_google_slides_export)

## Phase 1: Setup & Google Authentication
- [ ] Task: Gem dependency setup
  - [ ] Add `google-apis-slides_v1` and `google-apis-drive_v3` to `Gemfile` and run `bundle install`.
- [ ] Task: Write failing tests for Authentication Manager
  - [ ] Write tests verifying client instantiation, token loading, and support for both OAuth2 credentials and Service Account JSON keys.
- [ ] Task: Implement Authentication Manager (`Arneis::GoogleAuthManager`)
  - [ ] Implement credential loading logic from environment variables (`GOOGLE_APPLICATION_CREDENTIALS` or `GOOGLE_WORKSPACE_CREDENTIALS`).
  - [ ] Implement client builder to return authenticated `Google::Apis::SlidesV1::SlidesService` and `Google::Apis::DriveV3::DriveService`.
  - [ ] Run authentication tests and verify they pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Setup & Google Authentication' (Protocol in workflow.md)

## Phase 2: Google Slides Creation & Formatting
- [ ] Task: Write failing tests for Slides Exporter
  - [ ] Mock the Google API calls to verify slide creation, layout matching, and request batching.
- [ ] Task: Implement Slides Exporter (`Arneis::GoogleSlidesExporter`)
  - [ ] Create blank presentation deck if no sticky presentation ID exists.
  - [ ] Implement mapping for `title_slide` layout.
  - [ ] Implement mapping for `default` and text-only layouts (parsing and writing bullet points).
  - [ ] Implement mapping for `left_image` layouts (uploading slide illustration image to Google Drive and inserting it).
  - [ ] Run exporter tests and verify they pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Google Slides Creation & Formatting' (Protocol in workflow.md)

## Phase 3: Sticky Reference & In-Place Updating
- [ ] Task: Write failing tests for sticky state behavior
  - [ ] Write tests verifying reading/writing `google_slides_id` from/to `.state.yaml` and idempotently updating slides in-place.
- [ ] Task: Implement Sticky Reference Persistence & In-Place Updates
  - [ ] Update state persistence to write `google_slides_id` and `google_slides_url` to `.state.yaml` on export.
  - [ ] Implement check for `google_slides_id` in `.state.yaml` on run, and update the existing slides in-place using batchUpdate (deleting existing slide elements and replacing them with updated content) instead of creating a new presentation.
  - [ ] Add `--google-slides` option to `arnectl apply` CLI to trigger the export.
  - [ ] Run state and integration tests and verify they pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Sticky Reference & In-Place Updating' (Protocol in workflow.md)
