# Specification - Google Slides Export (feature_google_slides_export)

## Overview
Introduce the ability to export presentations directly to Google Slides, maintaining a "sticky" reference to the created Google Slides presentation inside the output folder's `.state.yaml`. Subsequent exports will update the existing slide deck in-place.

## Functional Requirements
1. **Google Slides API Integration**: Integrate with the Google Slides API to create and edit presentations.
2. **Authentication Support**: Support both OAuth2 user credentials (leveraging existing workspace credentials/token flow) and Service Account credentials (`service_account.json` file path via environment variable `GOOGLE_APPLICATION_CREDENTIALS` or config).
3. **Slide Layout & Elements Mapping**:
   - Create a blank slide deck if no sticky ID exists.
   - Map PowerColon slides into Google Slides:
     - Title Slide: Large title text box and optional subtitle.
     - Text/Bullet Slide: Text box containing bullet points.
     - Image Slide (e.g., `left_image`): Insert the generated slide illustration image alongside the text box.
4. **Template Slide Deck ID (Low-Pri / TODO)**: Provide optional support for copying a template presentation ID instead of starting from a blank layout.
5. **Sticky Reference**:
   - Save the created presentation ID/URL in the output folder's `.state.yaml` file under `google_slides_id` and `google_slides_url`.
6. **In-place Updating (Idempotency)**:
   - If `google_slides_id` is present in `.state.yaml`, fetch the existing presentation and update its slide contents (updating text text-runs and replacing images) in-place instead of creating a new slide deck.

## Non-Functional/Technical Requirements
* Ruby library: Use the official Google API client gem (`google-apis-slides_v1`, `googleauth`).
* Error Handling: Gracefully log warnings if API limit is reached or connection is lost.

## Acceptance Criteria
- [ ] Successfully authenticates via OAuth or Service Account.
- [ ] Exports a presentation to a new Google Slides deck.
- [ ] Writes `google_slides_id` and `google_slides_url` to `.state.yaml`.
- [ ] Subsequent exports to the same directory update the existing slide deck in-place instead of creating a new one.
