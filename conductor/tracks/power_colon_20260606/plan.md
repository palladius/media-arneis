# Implementation Plan: Power:Colon - A Presentation Maker

## Phase 1: Schema & Core Domain [checkpoint: ]
- [x] Task: Define and implement `Arneis::Schema::PowerColonContract` for YAML validation [x] fe4d7bf
- [x] Task: Create `Arneis::PowerColon` domain model for parsing YAML and Markdown slides [x] 61098bc
- [x] Task: Implement unit tests verifying contract validation and parsing [x] 4ce493e
- [ ] Task: Conductor - User Manual Verification 'Schema & Core Domain' (Protocol in workflow.md)

## Phase 2: Orchestration & CLI Integration [checkpoint: 69d02dc]
- [x] Task: Integrate `PowerColon` into `Arneis::Orchestrator` apply loop [x] 69d02dc
- [x] Task: Add dry-run support to only print proposed actions/API calls [x] 69d02dc
- [x] Task: Implement presentation drafting/ideation command `arnectl generate PowerColon --topic "<topic>"` using Gemini [x] 69d02dc
- [x] Task: Write tests for cli integration, dry-run, and topic-based generation [x] 69d02dc
- [x] Task: Conductor - User Manual Verification 'Orchestration & CLI Integration' (Protocol in workflow.md) [x] 69d02dc

## Phase 3: Slide Generators & Export Formats [checkpoint: ]
- [ ] Task: Implement HTML/CSS slideshow generator using Marp/Reveal.js layout patterns
- [ ] Task: Integrate Nano Banana for generating context-aware slide illustrations
- [ ] Task: Add basic PowerPoint/Google Slides metadata export
- [ ] Task: E2E and unit tests for presentation compilation
- [ ] Task: Conductor - User Manual Verification 'Slide Generators & Export Formats' (Protocol in workflow.md)
