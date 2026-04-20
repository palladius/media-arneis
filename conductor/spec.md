# Track Specification: Implement Asynchronous Polling and State-Based Orchestration

## Track Overview
This track shifts the media generation model from **blocking synchronous** to **asynchronous polling**. The CLI will trigger generations and exit (or continue) immediately, storing operation IDs in the project state for later retrieval.

## User Stories
- **As a Developer,** I want `arnectl apply` to launch all 4 scenes and return in seconds, not 10 minutes.
- **As a User,** I want to run `arnectl status --update` to fetch the results of background generations whenever they are ready.

## Functional Requirements
- **Async Python Scripts:**
  - Update `util/generate_video.py` to support a `--start-only` mode that returns the `operation_name` immediately.
  - Implement a `check_status.py` (or mode in existing scripts) to poll a specific `operation_name`.
- **State Machine Update:**
  - Introduce a new status: `polling`.
  - Store `operation_id` and `start_time` in `.state.yaml` for each scene.
- **Orchestration Update:**
  - `Arneis::Orchestrator` must support "re-attachment" to existing operations.
  - `resume` command must intelligently call the status check for any task in `polling` state.
- **Visuals:**
  - Use the 🔵 emoji for tasks in the `polling` state.

## Acceptance Criteria
- [ ] `arnectl apply` launches all tasks and completes its own execution in < 30 seconds.
- [ ] `.state.yaml` contains real `operation_id` strings.
- [ ] Running `arnectl resume` successfully fetches a completed video from a background operation.
