# Tech Stack: Media Harness (Arneis)

## Core Language & Runtime
- **Language:** **Ruby** (preferred for its DRY principles and developer happiness).
- **Concurrency:** **Ruby Fibers** for lightweight, asynchronous media generation orchestration with active polling for long-running tasks.
- **AI & Machine Learning Integration**
- **LLM Interaction:** **`rubyllm`** gem (or similar) for interacting with Google Gemini.
- **Media Models:**
  - **Gemini 1.5 Pro/Flash:** For text generation and media understanding (feedback loops).
  - **Lyria:** For music and song generation.
  - **Nanobanana:** For image creation and editing.
  - **Veo:** For high-quality video generation.
  - **Chirp / Gemini TTS:** For high-fidelity audio narration.
- **Specialized Integrations:** **Vertex AI Creative Studio MCP** (via Hussain's tools) for advanced media handling.

## CLI & Orchestration
- **CLI Framework:** **Thor** (or similar) to implement the `arnectl` interface.
- **Workflow Management:** **`Justfile`** for task automation (installation, testing, execution).
- **Environment Management:** **`git-privatize`** (via Sakura) for secure `.env` handling.

## Data & Persistence
- **Specification Format:** **YAML** for defining Templates (Classes) and Objects (Instances).
- **State Management:** Local filesystem with a deterministic folder structure (e.g., `out/YYYYMMDD_HHMM/`).
- **Archiving:** `.trash/` directory for non-destructive feedback iterations.

## Testing & Quality Assurance
- **Framework:** **RSpec** or **Cucumber** for BDD-style testing.
- **Static Analysis:** Custom YAML parsers to validate Classes and Objects in sub-second time.
- **Tiered Evals:** Automated evaluation loops using Gemini 2.5 Flash (JSON) and Gemini 3 Pro (Multimodal Intent).

## Infrastructure (Future/V2)
- **Web Interface:** **Ruby on Rails** or **Sinatra** for the real-time creation dashboard.
- **Storage:** **Google Cloud Storage (GCS)** for cloud backup and persistence of expensive media artifacts.
