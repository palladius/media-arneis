# Track Specification: Implement Feedback Loop and Advanced Montage Orchestration

## Track Overview
This track adds an interactive feedback loop to `arnectl` and enhances the final video assembly process. It implements the `feedback` command to intelligently regenerate specific assets and uses an LLM to generate complex, project-specific `ffmpeg` montage commands.

## User Stories
- **As a Media Creator,** I want to give natural language feedback (e.g., "I don't like video 3") and have the system automatically identify the asset, archive it, and regenerate it.
- **As a Developer,** I want the final video montage to be driven by a plan-aware LLM that chooses the best `ffmpeg` filters and transitions.
- **As a User,** I want to see a complete dependency graph and status report that includes project-level tasks like background music and montage, with media-type emojis.

## Functional Requirements
- **Feedback Loop (`arnectl feedback --prompt "..."`):**
  - Use Gemini to parse user feedback and map it to a specific `asset_id` (e.g., "Scene3.video").
  - Archive the target asset and its receipts to a `.trash/` directory within the project folder.
  - Reset the asset's status to `pending` in `.state.yaml` to trigger regeneration on next `resume`.
- **Advanced Montage Orchestration:**
  - Update `VideoProject` to prompt Gemini for a deterministic `ffmpeg` command based on the full YAML plan.
  - Support background music juxtaposition.
- **Enhanced Status & Visuals:**
  - Move `graph.md` generation into the project's output folder.
  - Add media type emojis (🎥, 🎵, 📝) to `status` and `graph.md`.
  - Ensure project-level tasks (music, montage) are correctly tracked in state and status.

## Acceptance Criteria
- [ ] `arnectl feedback --prompt "I don't like video 3"` successfully marks Scene 3 for regeneration.
- [ ] Deleted assets are moved to `.trash/` with a timestamp.
- [ ] `just arnectl status` shows the background music and montage tasks with emojis.
- [ ] `graph.md` exists inside the project folder and includes all tasks with emojis.
