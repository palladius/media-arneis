# Initial Concept

see BDD specs in it

# Product Guide: Media Harness (Arneis)

## Overview
Media Harness is a "kubectl-like" orchestration tool for complex media creation. It leverages Google's state-of-the-art AI models (Gemini, Lyria, Nanobanana, Veo, Chirp) to transform high-level "Templates" (Classes) and user-provided "YAML Specifications" into rich, multi-part media artifacts such as videos, stories, and comic books.

## Core Vision
To provide a deterministic, testable, and efficient framework for asynchronous media generation where complex dependencies are managed automatically, and the creation process is transparent and interactive.

## Target Users
- **Media Creators:** Individuals looking to generate high-quality stories, videos, or comics using AI templates.
- **Developers:** Users who want a CLI tool for local experimentation and BDD-driven media pipelines.

## Key Features
- **Template-Driven Creation:** Use prebaked YAML templates for "Kids Stories", "Video Projects", and "Comic Strips".
- **Asynchronous Orchestration:** Parallel execution of media generation tasks (Text, Image, Audio, Video) with dependency management.
- **Multimodal E2E Verification:** Optional `--verify` flag to trigger automated JSON schema validation and vision-based intent matching for generated artifacts.
- **Mock Abolition:** Support for "fail-fast" execution via `ARNEIS_NO_MOCK=true`, ensuring only real, high-fidelity artifacts are produced.
- **`kubectl`-like Interface:** Familiar command-line interactions (e.g., `apply`, `status`, `feedback`, `stats`).
- **Feedback Loop:** Interactive refinement of generated parts without destructive edits (archiving to `.trash`).
- **Resource Tracking:** Logging of execution time, token usage, and estimated cost for every call.
- **Real-time Status:** Colorful, emoji-rich progress tracking with visual dependency mapping.

## Goals
- **Deterministic Testing:** Ensure that the structure and non-LLM parts of a creation are statically testable.
- **DRY & Defaults:** Minimize configuration by providing smart defaults for models and parameters.
- **Performance:** Low-latency status checks ("Larry-Sergey latency").
- **Cost Transparency:** Detailed breakdown of model usage and expenditure.
