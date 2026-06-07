# 📖 Arneis User Manual

> [!NOTE]
> **Arneis (Media Harness) Version: 0.2.7**
> This manual serves as the primary user reference for Arneis. To prevent documentation drift, the version above is automatically tested against the system version file.

Welcome to the **Arneis (Media Harness)** User Manual. Arneis is a powerful orchestration tool designed to bridge the gap between high-level creative vision and low-level AI media generation. 

Inspired by `kubectl`, Arneis allows you to manage complex media projects using a declarative YAML-based approach.

---

## 🚀 Key Orchestration Capabilities

Arneis manages multi-part media generation using Ruby Fibers for parallel asynchronous task execution, state persistence, and automated evaluation.

- **Parallel Task Execution**: Tasks (generating images, writing narratives, fetching audio, producing videos) execute concurrently where possible to minimize production latency.
- **State Persistence & Resumption**: All progress is logged to a hidden `.state.yaml` file in the project's output directory. If stopped or interrupted, Arneis resumes only pending or failed tasks.
- **Automated Evaluations (EVALs)**: Built-in LLM-as-a-Judge criticizes generated artifacts, awarding quality scores (e.g., ⭐ 8/10) and flagging substandard generations for manual review or automatic regeneration.
- **Dependency Graphs**: Visual representation of project tasks and their dependencies using Mermaid.js.

---

## 🏗️ Supported Project Types (CUJs)

Arneis structures media creation into different templates (classes). Each corresponds to a specific creative project type:

### 1. 🎞️ VideoProject
An orchestration pipeline for producing multi-scene videos with background music and full montage concatenation.
- **Visuals**: Enhanced prompts sent to **Veo** to generate individual scene clips.
- **Audio**: A full-length background track generated using **Lyria**.
- **Montage**: LLM-driven `ffmpeg` command synthesis to concatenate scenes and mix in background music.
- **Marketing Package**: Automatically produces supporting promo copy, tweets, and teaser GIFs under the `marketing/` subdirectory.

### 2. 📚 KidsStory
A workflow that produces illustrated children's books with audio narrations and translations.
- **Narrative Enrichment**: Generates comprehensive stories (500–1000 words per chapter) from short, raw descriptions.
- **Character Consistency**: Integrates a designated character ID (e.g., `yukihiro`, `riccardo`) to inject physical traits and character reference images into the image generator prompt.
- **Audio & Translation**: Translates text into multiple languages and runs **Chirp** to generate localized audio tracks, which are then stitched together into a complete story audiobook.
- **Output**: Packages illustrations, narratives, and audio links in a beautifully presented `STORY.md` file.

### 3. 👤 CharacterImage
Designed to produce high-resemblance character illustrations in custom scenarios.
- **Multi-character Support**: Can generate images featuring single or multiple characters.
- **Style Mandate**: Generates cinematic, photorealistic portraits unless cartoon or stylized themes are requested.
- **Reference Images**: Pulls consistency images from character profile directories to seed the image generator.
- **Feedback Loop**: Supports adding a `feedback` node inside the spec containing errors from previous attempts to guide Imagen revisions.

### 4. 🎨 ComicStrip
A panel-by-panel comic layout generation engine.
- **Structure**: Organizes the comic into rows, with 1 to 5 panels per row.
- **Components**: Generates layouts, dialogue bubbles, and art styles (Manga, watercolor, comic noir) for each panel.
- **Sequence Flow**: Prompts Gemini to maintain action continuity and narrative flow between panels.

### 5. 📊 PowerColon
An automated text-to-presentation engine that compiles PowerPoint slide decks.
- **Layouts**: Ideates slide flows, headers, bullet points, and visual motifs from specifications.
- **Visual Assets**: Calls Imagen to produce high-quality background or illustration images matching the slide theme.
- **Presentation Export**: Combines the assets, layouts, and typography into a professional `.pptx` deck using the Ruby powerpoint engine.

---

## 👤 Character Consistency & Profiles

Character specifications are stored in `data/characters/` in YAML format. The system resolves characters by folder name, file name, or custom identifiers inside the specification.

### Character Profiles
A character profile consists of:
- **Biographical Data**: Name, nickname, gender, and nationality.
- **Personality & Visual Look**: A detailed descriptive summary of physical characteristics (e.g., hair style, glasses, build) and persona traits.
- **Consistency Images**: A folder containing high-quality photos/renders of the character. These are parsed by the orchestration engine and sent as reference images to Imagen to ensure high facial and clothing resemblance.

---

## 💻 CLI Commands & Invocations

All commands can be run via the `arnectl` CLI tool or wrapped through the `Justfile`.

### 1. Ideate & Pitch
Analyze a raw research document and output a structured project plan.
```bash
just arnectl research-pitch data/samples/VideoProject/rubycon_research.md
```

### 2. Execute and Orchestrate
Apply a declarative YAML specification to start the parallel generation loop.
```bash
just arnectl apply data/samples/VideoProject/rubycon_sales_pitch.yaml
```

### 3. Check State
Inspect the current status of scenes, tasks, evaluations, and project costs.
```bash
just arnectl status out/latest_project/
```

### 4. Render Dependency Graph
Visualize task execution dependencies.
```bash
just arnectl graph data/samples/VideoProject/rubycon_sales_pitch.yaml
```

### 5. Validate Artifacts
Verify that all produced media files meet the expected codecs, durations, and sizes.
```bash
just arnectl verify out/latest_project/
```

### 6. Generate Direct Assets
Initiate direct image generations for consistent characters.
```bash
just arnectl generate CharacterImage -c riccardo -p "Riccardo as a cyberpunk hacker in Tokyo"
```

---

## 🔄 Resilience & State Model

Every project output directory contains a `.state.yaml` file tracking the status of each component:
- `initialized`: Ready to start.
- `in_progress`: Task is currently executing.
- `polling`: Asynchronous AI operation running (e.g., Veo video generation) waiting for completion check.
- `done` / `verified`: Task completed successfully and verified.
- `done_with_warnings` / `failed`: Issue detected, but does not block execution if bypassable, or failed.

If an orchestration process is stopped, running `apply` again reads the `.state.yaml` and starts only the tasks that aren't marked `done` or `verified`.
