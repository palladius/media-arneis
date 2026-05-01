# Implementation Plan: `arnectl generate` with Evaluation Support

## Phase 1: CLI Options & Basic Integration
- [ ] Task: Add `--eval` and `--no-eval` flags to `arnectl generate` in `lib/arneis/cli.rb`.
- [ ] Task: Update `generate` command to pass the `verify` option to the project processor.
- [ ] Task: Write unit tests to verify that flags are correctly parsed and passed.
- [ ] Task: Conductor - User Manual Verification 'CLI Options & Basic Integration' (Protocol in workflow.md)

## Phase 2: Evaluation Orchestration
- [ ] Task: Integrate evaluation tasks into the `process` method of `CharacterImage`.
- [ ] Task: Implement "Prompt Matching" evaluation in `Arneis::Evaluator`.
- [ ] Task: Implement "Text Quality" evaluation in `Arneis::Evaluator`.
- [ ] Task: Ensure evaluation tasks depend on the generation task finishing first.
- [ ] Task: Write unit tests for the updated orchestration logic.
- [ ] Task: Conductor - User Manual Verification 'Evaluation Orchestration' (Protocol in workflow.md)

## Phase 3: Fail-Fast & Persistence
- [ ] Task: Implement a check in `Arneis::Cli` to exit non-zero if any evaluation fails or has a low score.
- [ ] Task: Ensure evaluation results are correctly saved in `.asset.json` files for ad-hoc generations.
- [ ] Task: Update `status` command to highlight failed evaluations for ad-hoc projects.
- [ ] Task: Write E2E tests for the full `generate --eval` flow.
- [ ] Task: Conductor - User Manual Verification 'Fail-Fast & Persistence' (Protocol in workflow.md)
