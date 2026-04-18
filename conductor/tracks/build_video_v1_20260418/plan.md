# Implementation Plan: Build core Video Project orchestration and arnectl CLI (v1)

## Phase 1: Project Scaffolding & Initial CLI
- [x] Task: Set up the project structure for Ruby with a `Justfile`.
- [x] Task: Create the `arnectl` CLI shell with `thor`.
- [x] Task: Implement `arnectl version` and initial help messages.
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: YAML Parsing & Template Engine
- [x] Task: Write Tests for YAML schema validation for the `VideoProject` class.
- [x] Task: Implement the YAML parser and `VideoProject` template logic.
- [x] Task: Write Tests for deterministic output folder creation.
- [x] Task: Implement the output folder structure and state file (`.state.yaml`).
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Core Orchestration & Async (Fibers)
- [x] Task: Write Tests for the dependency graph builder.
- [x] Task: Implement the dependency graph and state machine.
- [x] Task: Write Tests for asynchronous execution with Ruby Fibers.
- [x] Task: Implement the core orchestration engine to process the graph.
- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: CLI Status & Stats View
- [x] Task: Write Tests for the `status` command output formatting (emojis!).
- [x] Task: Implement the `arnectl status` "watch" view with dependency mapping.
- [x] Task: Write Tests for the `stats` command (token/cost reporting).
- [x] Task: Implement the `arnectl stats` report.
- [x] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)

## Phase 5: Initial Media Parts Integration (Dummy/Mock)
- [x] Task: Create mock generators for Video, Music, and Narration to test orchestration.
- [x] Task: Integrate mock generators into the full pipeline for a 4-subchapter Video.
- [x] Task: Verify end-to-end execution of `arnectl apply` with mocks.
- [x] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)
