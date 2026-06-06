# Specification: Power:Colon - A Presentation Maker

## Overview
Power:Colon is an automated, text-to-presentation generation engine designed to compile structured YAML configurations and Markdown content files into fully styled presentation decks. It integrates AI-driven visual design (using Nano Banana for character-consistent and context-aware slide illustrations) and offers multiple export options, focusing on HTML/CSS (Reveal.js/Marp) for v0.1 while keeping PDF/Google Slides/PowerPoint in mind for v1.0.

It integrates seamlessly with the existing `media-arneis` structure, processed via `arnectl apply`.

---

## 👥 User Story
**As a** presenter,  
**I want to** define my presentation's structure in YAML and slide content in separate Markdown files,  
**So that** I can automatically compile them into styled slide decks with relevant, AI-generated, character-consistent visuals.

---

## 📋 Functional Requirements

### 1. Structure & Configuration (YAML)
- The presentation structure MUST be defined in a `presentation.yml` file under `data/` or a target project directory.
- The YAML MUST follow the `media-arneis` K8s-style schema:
  - `apiVersion: media-arneis.palladius.it/v1`
  - `kind: PowerColon`
  - `metadata`: `name`, `template`, etc.
  - `spec`: containing slide definitions, global styles, and assets.
- Slide entries MUST define:
  - `file`: Path to the Markdown file containing the slide content (stored under `data/presentations/slides/`).
  - `style`: The layout template name (e.g., `title_slide`, `chapter`, `default`, `left_image`).

### 2. Slide Content (Markdown)
- Slide content MUST live in plain Markdown files referenced by the YAML, placed under `data/presentations/slides/`.
- Structure within Markdown files:
  - Heading 1 (`#`) represents the slide title.
  - Bullet points (`-`, `*`) represent core talking points.
  - Inline images or custom tags specify target assets.

### 3. Predefined Slide Templates (Styles)
- **`title_slide`**: Main presentation title and author metadata layout.
- **`chapter`**: Visual slide with clean typography to introduce sections.
- **`default`**: A classic title and bullet list format.
- **`left_image`**: Split-screen layout featuring a vertical image on the left (2/3 width) and title/bullets on the right.

### 4. AI-Driven Image Generation (Nano Banana)
- When a slide style requires an image (e.g., `left_image`), the generator MUST automatically prompt **Nano Banana** to produce a contextually relevant image.
- Prompt construction MUST combine the slide markdown text and character profile (if a `character_id` is supplied) to ensure consistency.
- **API Throttling**: The generation tasks must use the `Arneis::Orchestrator`'s built-in semaphore (bounded by `Arneis::Config.max_concurrent_tasks`) to limit concurrent API calls and avoid rate-limiting errors or hammering the Nanobanana API.

### 5. Build & CLI Integration (`arnectl apply`)
- Integrates directly into the existing `arnectl apply <yaml>` orchestration.
- Output files must be saved under a dedicated subfolder `out/power_colon/<project_name>/`.
- **Parallel & Re-entrant Generation**:
  - Image generation and compilation tasks MUST run in parallel using fiber-based concurrency to achieve fast deck creation (under a minute).
  - Re-entrant compilation: Check if slide markdown or prompt has changed. If the target image already exists and prompt inputs are identical, skip generation to save time and API quota.
  - `--dryrun`: Enable checking what operations and API calls are required without triggering live calls.

### 6. Export Options
- **v0.1**: HTML/CSS Slideshow (Reveal.js or Marp style single page).
- **v1.0**: Extend to PDF, Google Slides, and PowerPoint (`.pptx`).

### 7. Ideation / Drafting Phase (Topic-to-Presentation)
- Support drafting a complete presentation from a high-level topic (e.g. `"Openclaw vs Hermes"`).
- A CLI command (e.g. `arnectl generate PowerColon --topic "Topic Name"`) will use Gemini to:
  1. Generate the presentation YAML file.
  2. Create separate Markdown files for each slide under `data/presentations/slides/`.
- This allows a user to write their high-level presentation idea, get structured draft files, modify them, and compile them with `arnectl apply`.

---

## 🎯 Acceptance Criteria
- [ ] Implement `Arneis::Schema::PowerColonContract` in [schema.rb](file:///home/riccardo/git/media-arneis/lib/arneis/schema.rb) to validate the `PowerColon` YAML schema.
- [ ] Create parser and compiler class `Arneis::PowerColon` matching the layout template pattern.
- [ ] Integrate into `arnectl apply` (via [orchestrator.rb](file:///home/riccardo/git/media-arneis/lib/arneis/orchestrator.rb) and [cli.rb](file:///home/riccardo/git/media-arneis/lib/arneis/cli.rb)) to handle `kind: PowerColon`.
- [ ] Support `--dryrun` flag to output proposed actions/calls without hitting live APIs.
- [ ] Export working HTML/CSS presentation structure to `out/power_colon/<project_name>/`.
- [ ] Support `arnectl generate PowerColon --topic "<topic>"` to draft a complete presentation structure (YAML + Markdown files) under `data/presentations/`.
- [ ] Unit tests verify correct structure parsing and page Markdown mapping.
