# Specification: Configurable Post-Creation Actions

## Overview
Add CLI flags and environment variable support to control whether automated evaluation and file opening occur after a media artifact (image, audio, or video) is created.

## Functional Requirements
- **CLI Flags:**
  - `--eval` / `--no-eval`: Toggle automated evaluation using `Arneis::Evaluator`.
  - `--open` / `--no-open`: Toggle opening the generated file using the system's default opener (`open` on macOS, `xdg-open` on Linux).
- **Environment Variables:**
  - `ARNEIS_EVAL_ENABLED`: Set to `true` or `false` to set the default for evaluation.
  - `ARNEIS_OPEN_ENABLED`: Set to `true` or `false` to set the default for opening files.
- **Precedence:**
  1. CLI Flag (highest precedence).
  2. Environment Variable.
  3. Default: `true` (Enabled).
- **Scope:**
  - Affects all media generation commands in `arnectl`.
  - Update help text to describe these new flags and their associated environment variables.

## Non-Functional Requirements
- **Consistency:** Use existing Ruby patterns for flag and ENV handling.
- **Usability:** Ensure clear feedback in the CLI when an action is skipped due to configuration.

## Acceptance Criteria
- [ ] Running `arnectl` with `--no-eval` skips the evaluation step.
- [ ] Running `arnectl` with `--no-open` skips opening the file.
- [ ] Setting `ARNEIS_EVAL_ENABLED=false` in `.env` disables evaluation by default.
- [ ] Setting `ARNEIS_OPEN_ENABLED=false` in `.env` disables opening files by default.
- [ ] Help text correctly describes the flags and environment variables.

## Out of Scope
- Implementing the evaluation logic itself (use existing `Arneis::Evaluator`).
- Implementing the "open" logic from scratch (use system commands or existing logic where applicable).
