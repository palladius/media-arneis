# Track Specification: Build core Video Project orchestration and arnectl CLI (v1)

## Track Overview
This track focuses on implementing the core orchestration engine for the "Video Project" template and the basic command-line interface `arnectl`. The goal is to provide a functional end-to-end pipeline that generates a 32-second video from a YAML specification, following the "Arneis" principles of asynchronicity and technical transparency.

## User Stories
- **As a Media Creator,** I want to define a 32s video with 4 subchapters (8s each) in a YAML file so that I can automatically generate a high-quality video with sub-stories and media.
- **As a Developer,** I want to use `arnectl apply` to orchestrate the generation process so that I can track progress and dependencies in real-time.

## Functional Requirements
- **Template Implementation:**
  - Create the `VideoProject` class (Template) with support for 4 subchapters.
  - Subchapters should support Video (Veo), Music (Lyria), and Narration (Chirp).
- **Orchestration Engine:**
  - Build a dependency graph based on the YAML input.
  - Use Ruby Fibers for asynchronous execution of media generation tasks.
  - Implement a state machine to track task statuses (Done, In Progress, Ready, Waiting).
- **CLI (`arnectl`):**
  - `apply <yaml_path>`: Parse YAML, initialize output folder, and start generation.
  - `status <folder_path>`: Show the colorful status "watch" view.
  - `stats <folder_path>`: Report on model usage and cost.

## Acceptance Criteria
- [ ] `arnectl apply` successfully parses a valid Video YAML and creates an output directory.
- [ ] Generation process respects dependencies (e.g., narration follows text generation).
- [ ] `arnectl status` displays a live, emoji-rich view of the progress.
- [ ] All generated media (dummy for initial tests, real for v1) exists in the output folder.
- [ ] Final artifacts are archived correctly if a feedback loop is triggered.
