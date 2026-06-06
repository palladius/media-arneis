# Specification: `arnectl generate` with Evaluation Support

## Overview
This track introduces formal evaluation support to the `arnectl generate` command. Users can now opt-in or opt-out of automated quality checks for generated media. When enabled, the system will perform several tiered evaluations (Face Consistency, Prompt Matching, Text Quality) to ensure high-fidelity outputs.

## Functional Requirements
- **CLI Flags:**
  - `--eval`: Explicitly enable evaluations.
  - `--no-eval`: Disable all evaluations.
- **Default Behavior:** Evaluations are enabled by default (`--eval`).
- **Integrated Orchestration:**
  - Evaluations are added as dependent tasks in the `Orchestrator`.
  - Generation tasks must finish before evaluation tasks start.
- **Supported Evaluations:**
  - **Face Consistency (Tier 2):** Uses Gemini Vision to compare the generated image against character reference images.
  - **Prompt Matching (Tier 2):** Verifies that the visual content aligns with the user's intent.
  - **Text Quality/Typos (Tier 1/2):** Checks generated text (e.g., in KidsStory or prompt enhancements) for typos and grammatical correctness.
- **Fail-Fast Mechanism:**
  - The CLI command will exit with a non-zero status if any evaluation score falls below a defined threshold (default: 7/10).
- **Observability:**
  - Evaluation results (scores, verdicts, reasons) are printed to the console and saved in `.asset.json` files.

## Non-Functional Requirements
- **Performance:** Evaluations should run asynchronously using Fibers to minimize total execution time.
- **Robustness:** Failure of an evaluator model (e.g., 429) should be reported but not necessarily crash the entire generation if retries are possible.

## Acceptance Criteria
- Running `arnectl generate CharacterImage ... --no-eval` skips all evaluation steps.
- Running `arnectl generate CharacterImage ... --eval` (or default) triggers Face Consistency and Prompt Matching evals.
- A low score (e.g., 4/10) causes the command to report failure.
- Evaluation metadata is correctly persisted in the output directory.

## Out of Scope
- Re-generation logic (covered by `arnectl redo`).
- Interactive feedback within the `generate` command (use `arnectl feedback` instead).
