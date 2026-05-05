
# 🍷 Arneis (Media Harness)

![Arneis Logo](./logo.png)

Arneis is a "kubectl-like" orchestration tool for complex media creation. It leverages Google's state-of-the-art AI models (Gemini, Lyria, Nanobanana, Veo, Chirp) to transform high-level Templates and YAML Specifications into rich, multi-part media artifacts.

## Features

- **Template-Driven:** Build Videos, Kids Stories, and Comic Strips using pre-defined classes.
- **Async Orchestration:** Parallel execution of generation tasks with Ruby Fibers.
- **Visual Feedback:** Emoji-rich progress tracking and Mermaid.js dependency graphs.
- **Technical Transparency:** Detailed resource tracking (tokens, cost) and artifact validation.

## 🏗️ Supported Project Templates (CUJs)

| Template | Description | Status |
| :--- | :--- | :--- |
| **VideoProject** | Multi-scene video with background music and montage. | ✅ **Done** |
| **KidsStory** | Illustrated storybook with character consistency. | 🏗️ **WIP** |
| **ComicStrip** (Fumetto) | Panel-by-panel comic narratives. | 🏗️ **WIP** |

## 🧪 Testing and Quality

Arneis includes a comprehensive testing suite to ensure orchestration reliability and model compatibility.

### 1. Unit Tests (Fast)
Run standard unit tests for core logic and configuration:
```bash
just test
```

### 2. End-to-End Tests (Slow & Expensive)
Run full end-to-end tests that make live calls to Google AI models (Imagen, Veo, Lyria, Chirp). These tests verify that real artifacts are produced and validated.
```bash
# Requires ARNEIS_NO_MOCK=true (enabled automatically by just)
just test-e2e
```

### 3. Mock Abolition
To force Arneis to fail fast if an AI generation task fails (instead of falling back to creating mock files), use the `ARNEIS_NO_MOCK` environment variable:
```bash
ARNEIS_NO_MOCK=true arnectl apply my_project.yaml
```
*Note: Mocks are still enabled during `--dryrun` for testing project structure without AI costs.*

## Documentation

For a deeper dive into how Arneis works, check out the [User Manual](docs/user_manual.md).

## Usage

```bash
# Verify your environment and models
just test-all-models

# Research a project and generate a pitch YAML
just arnectl research-pitch data/samples/VideoProject/rubycon_research.md

# Apply a media plan from 2 different examples.
just arnectl apply data/samples/VideoProject/rubycon_sales_pitch.yaml
just arnectl apply data/samples/VideoProject/rubycon_french_falling_rubies.yaml 

# Check status
just arnectl status out/latest_folder

# Verify generated artifacts
just arnectl verify out/latest_folder

# Generate a dependency graph (Mermaid.js)
just arnectl graph data/samples/VideoProject/rubycon_sales_pitch.yaml
```
