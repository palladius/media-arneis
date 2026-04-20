# Track Specification: Implement KidsStory Class

## Overview
This track introduces the `KidsStory` class, a new media type designed for multi-page, illustrated children's stories. It leverages `Imagen` for illustrations, `Lyria` for background music, and Gemini for story generation and scene enhancement.

## Functional Requirements
1. **K8s-Compliant Structure:** Implement `apiVersion: media-arneis.palladius.it/v1` and `kind: KidsStory`.
2. **Multi-Page Orchestration:** `KidsStory` projects will consist of N pages, each with a text description and a corresponding illustration.
3. **Character Consistency:** Integration with the `Character` model to ensure the protagonist's visual consistency across all illustrations.
4. **Coordinated Background Music:** A project-wide background music track generated via `Lyria`.
5. **Hierarchical Organization:** Project folder structure:
   - `story/page1/illustration.png`, `story/page1/text.txt`
   - `audio/background_music.wav`

## Acceptance Criteria
- [ ] `arnectl apply` for a `KidsStory` YAML correctly hydrates and initializes the project.
- [ ] Orchestration correctly generates illustrations for each page using character references.
- [ ] Real background music is generated and verified.
- [ ] Final project status correctly reflects completion of all pages and music.

## Out of Scope
- Narrative PDF/E-book generation (future track).
