# Implementation Plan: Build core Video Project orchestration and arnectl CLI (v1)

## Phase 1: Project Scaffolding & Initial CLI
- [ ] Task: Set up the project structure for Ruby with a `Justfile`.
- [ ] Task: Create the `arnectl` CLI shell with `thor`.
- [ ] Task: Implement `arnectl version` and initial help messages.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: YAML Parsing & Template Engine
- [ ] Task: Write Tests for YAML schema validation for the `VideoProject` class.
- [ ] Task: Implement the YAML parser and `VideoProject` template logic.
- [ ] Task: Write Tests for deterministic output folder creation.
- [ ] Task: Implement the output folder structure and state file (`.state.yaml`).
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Core Orchestration & Async (Fibers)
- [ ] Task: Write Tests for the dependency graph builder.
- [ ] Task: Implement the dependency graph and state machine.
- [ ] Task: Write Tests for asynchronous execution with Ruby Fibers.
- [ ] Task: Implement the core orchestration engine to process the graph.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: CLI Status & Stats View
- [ ] Task: Write Tests for the `status` command output formatting (emojis!).
- [ ] Task: Implement the `arnectl status` "watch" view with dependency mapping.
- [ ] Task: Write Tests for the `stats` command (token/cost reporting).
- [ ] Task: Implement the `arnectl stats` report.
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)

## Phase 5: Initial Media Parts Integration (Dummy/Mock)
- [ ] Task: Create mock generators for Video, Music, and Narration to test orchestration.
- [ ] Task: Integrate mock generators into the full pipeline for a 4-subchapter Video.
- [ ] Task: Verify end-to-end execution of `arnectl apply` with mocks.
- [ ] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)
