# Track Specification: Power:Colon - A Presentation Maker

## Overview
Power:Colon is an automated, text-to-presentation generation engine designed to compile structured YAML configurations and Markdown content files into fully styled presentation decks. It integrates AI-driven visual design (using Nano Banana for character-consistent and context-aware slide illustrations) and offers multiple export options including HTML, PDF, Google Slides, and PowerPoint.

---

## 👥 User Story
**As a** presenter,  
**I want to** define my presentation's structure in YAML and slide content in Markdown,  
**So that** I can automatically compile them into styled slide decks with relevant, AI-generated, character-consistent visuals.

---

## 📋 Functional Requirements

### 1. Structure & Configuration (YAML)
- The presentation structure MUST be defined in a `presentation.yml` file under `data/` or a target project directory.
- The YAML MUST follow the `media-arneis` K8s-style schema with:
  - `apiVersion: media-arneis.palladius.it/v1`
  - `kind: PowerColon`
  - `metadata` including name and template
  - `spec` containing slide definitions, global styles, and assets.
- Slide entries MUST define:
  - `file`: Path to the Markdown file containing the slide content.
  - `style`: The layout template name (e.g., `title_slide`, `chapter`, `default`, `left_image`).

### 2. Slide Content (Markdown)
- Slide content MUST live in plain Markdown files referenced by the YAML.
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

### 5. Build & Compilation Process (`make all` / `arnectl`)
- Must support automated building and re-entrant generation:
  - Re-entrant compilation: Skip already generated assets if content/prompts have not changed.
  - `--dry-run`: Enable checking what operations and API calls are required without triggering live calls.
- Output files must be saved under a designated output directory (e.g. `out/`).

### 6. Export Options
- **HTML/CSS Slideshow**: Render slides using standard web technologies (e.g. Reveal.js, Marp, or simple HTML/CSS pages).
- **PDF**: Compiled slides formatted for standard printing/sharing.
- **Google Slides & PowerPoint (.pptx)**: Exportable structure maps to standard editable slides.

---

## 🎯 Acceptance Criteria
- [ ] Implement `Arneis::Schema::PowerColonContract` to validate the `PowerColon` YAML schema.
- [ ] Create parser and compiler class `Arneis::PowerColon` matching the layout template pattern.
- [ ] Provide CLI subcommand or integrate into `arnectl apply` to handle `kind: PowerColon`.
- [ ] Support `--dryrun` flags to output proposed actions/calls without hitting live APIs.
- [ ] Export working HTML/CSS presentation structure to the output directory.
- [ ] Export basic editable `.pptx` or Google Slides configuration maps.
- [ ] Unit tests verify correct structure parsing and page Markdown mapping.

---

## 🚫 Out of Scope (Future Phases)
- Multi-user collaboration platforms or real-time web editors.
- Import from PDF/PowerPoint/Google Slides back into YAML/Markdown.
