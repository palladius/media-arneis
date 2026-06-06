# Implementation Plan: Evaluation Feedback Loop

## Phase 1: CLI Configuration and Parsing
- [x] Task: Write tests for `arnectl` CLI options to ensure `--retry` flag is parsed correctly and rejects invalid inputs.
- [x] Task: Implement `--retry <run_id>` option in `lib/arneis/cli.rb` (or equivalent CLI setup).
- [x] Task: Conductor - User Manual Verification 'CLI Configuration and Parsing' (Protocol in workflow.md)

## Phase 2: Feedback Metadata Retrieval
- [x] Task: Write tests for a new method to locate and parse `.asset.json` files given a `run_id`.
- [x] Task: Implement `Arneis::FeedbackLoader` (or similar) to scan `out/<run_id>`, read the `.asset.json`, and extract the original prompt, evaluation errors, previous image path, and original command.
- [x] Task: Conductor - User Manual Verification 'Feedback Metadata Retrieval' (Protocol in workflow.md)

## Phase 3: Prompt Injection
- [x] Task: Write tests to verify that the generation prompt correctly incorporates feedback data (errors, previous image, original context) when provided.
- [x] Task: Update the generation logic (e.g., in `Arneis::Generator::Gemini` or `Task`) to format and append the retrieved feedback to the new LLM prompt.
- [x] Task: Conductor - User Manual Verification 'Prompt Injection' (Protocol in workflow.md)

## Phase 4: User Guidance on Failure
- [x] Task: Write tests to ensure the Orchestrator outputs a specific retry command when an evaluation fails.
- [x] Task: Update the `verify_task` method in `Arneis::Orchestrator` to print a user-friendly hint (e.g., `To retry with eval feedback, run: arnectl generate ... --retry <run_id>`) upon evaluation failure.
- [x] Task: Conductor - User Manual Verification 'User Guidance on Failure' (Protocol in workflow.md)