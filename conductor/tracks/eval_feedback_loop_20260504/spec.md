# Specification: Evaluation Feedback Loop

## Overview
Implement a feedback loop mechanism that allows the generation process to learn from previous evaluation failures. When an artifact fails evaluation (e.g., intent mismatch), the subsequent retry will be provided with the original context, the failed artifact, and the specific evaluation error to improve the next generation attempt.

## Functional Requirements
1. **CLI Retry Mechanism:** 
   - Add a `--retry <run_id>` flag to `arnectl generate`.
   - The system must locate the failed assets and their `.asset.json` metadata within the specified run directory.
2. **Context Injection:** When retrying, the prompt sent to the LLM/Generation model MUST include:
   - The Original Prompt.
   - The specific Evaluation Errors from the previous run.
   - The Previous Generated Image (as multimodal context).
   - The original CLI Command executed.
3. **Manual Retry Facilitation:** When an evaluation fails during a standard run, the CLI should output a helpful message containing the exact command the user can copy-paste to retry with feedback (e.g., `To retry with eval feedback, run: arnectl generate ... --retry <run_id>`).
4. **Foundation for Automation:** The architecture should support future automated retries (e.g., Orchestrator auto-retrying up to N times before ultimate failure), though the immediate scope is to enable the manual CLI retry.

## Non-Functional Requirements
- **Resilience:** The retry mechanism should gracefully handle missing metadata files or images.
- **Traceability:** Retried generations should be logged in a way that links them back to the original failed attempt.

## Acceptance Criteria
- [ ] Running `arnectl generate ... --retry <run_id>` successfully parses the previous evaluation errors from `<run_id>`.
- [ ] The LLM generation prompt for the retry explicitly includes the evaluation feedback and the previous image.
- [ ] A failed generation prints a "retry" command to the console for the user.

## Out of Scope
- Fully automated, unattended retry loops within the Orchestrator (this will be a follow-up feature; this track builds the foundation).