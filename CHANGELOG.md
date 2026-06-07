# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.8] - 2026-06-07

### Added
- 📸 feat: Added `just extract-bestof` script and engine to scrape both images and videos from `out/` and copy them to type-specific directories (`pics/` and `videos/`).
- ⚙️ feat: Implemented flat category-based subfolders (`rubycon/` and `family/`) under target directories to simplify organization and prevent deep nesting.
- 🧹 feat: Supported rotation cleanup (`--clean` / `-c` and `--rotate-days`) to safely delete old project runs after preserving files.
- 🧪 test: Added comprehensive RSpec unit tests validating video routing, flat categorization, duplicate skipping, and rotation.
- 🧪 test: Clean up testing semantics. Pointed `just test` (unit tests) to `just unit-test` (<5s runtime, using mocks), added `just integration-test` (real API calls) and `just e2e-test` (real API calls with evaluator).
- ⚙️ feat: Add timestamps to logging output by overriding `Kernel#puts` globally for non-vendored project files.
- 🐛 fix: Map `.mp4` video files to correct MIME-type `video/mp4` during multimodal intent check evaluations.



## [0.2.7] - 2026-06-07


### Added
- 📖 doc: Created comprehensive `docs/USER MANUAL.md` covering all engines (VideoProject, KidsStory, CharacterImage, ComicStrip, and PowerColon), characters configuration, and CLI invocations.
- ⚙️ feat: Created AI-focused skill folder `docs/skills/how-to-use-media-arneis/SKILL.md` to guide agents in running and updating the framework.
- 🧪 test: Added RSpec unit test `spec/arneis/documentation_spec.rb` to prevent version drift between `VERSION` and documentation.
- 🛠️ chore: Safe-guarded unit tests against local `.env` mock-abolition bleeding, and updated `Justfile` recipe commands to run via `ruby -S rspec` to avoid broken local shebangs.

## [0.2.6] - 2026-06-07

### Added
- 📽️ feat: Append a hidden/skipped credit slide to PowerPoint presentations containing version, GitHub link, and the PowerColon logo.
- ⚙️ chore: Dynamically load project version from the `VERSION` file in `lib/arneis.rb`.

## [0.2.5] - 2026-06-07

### Added
- 📽️ feat: Add native PowerPoint (`.pptx`) presentation generation via `powerpoint` gem, compiling both text bullet points and generated illustration images automatically.

## [0.2.4] - 2026-06-07

### Added
- 📁 feat: Organize template folder by category, creating subdirectories per template type under `data/templates/`.
- 🔍 feat: Implement recursive scanning using `Dir.glob` to resolve templates from subdirectories dynamically.
- ⚙️ feat: Add `just test-power-colon` target to run PowerColon mock presentation on a sticky output directory (`out/sticky-power-colon`).

## [0.2.3] - 2026-06-07

### Added
- 🧠 feat: Implement `--retry <run_id>` option in `arnectl generate` to retry failed generations using evaluation feedback and previous run images as multimodal context.
- 📂 feat: Capture original CLI command execution dynamically in project state configuration metadata.
- 🛡️ feat: Update orchestrator verification logic to display user-friendly retry hints on evaluation failure.
- 🧪 test: Added unit tests for CLI retry options, FeedbackLoader parsing, and Orchestrator retry suggestions.

## [0.2.2] - 2026-06-06

### Added
- 📽️ feat: Support both "grounded" (completely self-contained YAML with inline titles and contents) and "ideation" (topic-driven, dynamically generated slides) presentations for PowerColon.

## [0.2.1] - 2026-06-06

### Added
- 🎨 feat: Added refined muscular orange colon PowerPoint-style logo for PowerColon.
- 🤡 feat: Added purple color placeholder mock image for 4:3 slide aspect ratio.

## [0.2.0] - 2026-06-06

### Added
- 📽️ feat: Implement Power:Colon presentation maker (spec-driven slide deck parser and generator).
- 🧠 feat: LLM-driven presentation ideation and drafting (`arnectl generate PowerColon --topic "<topic>"`).
- 🤡 feat: Multi-colored, aspect-ratio-aware "Coming Soon" placeholder illustrations (1x1, 3x4, 4x3) for offline prototyping.
- 📁 feat: Export basic presentation structure mapping to `slides_export.json`.
- 🎨 feat: Added custom muscular orange colon presentation logo assets.

## [0.1.9] - 2026-05-17

### Fixed
- 🎬 fix: enforce `-shortest` and `-c:v copy` in LLM-generated `ffmpeg` montage commands to prevent infinite loop regressions and huge corrupted files.

### Changed
- 📦 chore: archive `e2e_eval_harness_20260430` conductor track as it is now complete and verified.

## [0.1.8] - 2026-05-05

### Added
- 🌱 feat: add visual feedback (with seedling emoji!) when environment variables are detected in `Config.load!`.
- 🏷️ feat: support namespaced environment variables `ARNEIS_OPEN`, `ARNEIS_EVAL` and their `_ENABLED` variants as preferred alternatives to generic `OPEN`/`EVAL`.
- 📝 docs: update `.env.dist` with namespaced environment variables.

## [0.1.7] - 2026-05-04

### Added
- 📂 feat: support `ARNEIS_FOLDER` environment variable for defaulting the media folder in CLI commands.
- 🔧 feat: improved project resumption logic with better handling of KidsStory pages.

## [0.1.6] - 2026-05-01

### Added
- 👤 feat: implement `CharacterImage` project kind for high-resemblance character portraits.
- 🔄 feat: add `arnectl redo` command to automatically reset and retry sub-optimal tasks.
- ⚖️ feat: enhance `Evaluator` with "VERDICT" for character consistency (e.g., "me somijja").
- 💡 `arnectl status` now suggests `redo` when low scores are detected.

### Fixed
- 🐛 Fix `KidsStory` orchestration bug where `image_output` was not correctly scoped.
- 🧪 Fix `Data Samples` tests to support all project kinds.

## [0.1.5] - 2026-04-20

### Fixed
- 🛡️ Improved CLI robustness: subcommands now correctly handle `--help` and `-h` flags even when passed as arguments, showing usage instructions instead of crashing.
- 📂 Added file existence checks in `Arneis::Hydrator` to provide cleaner error messages.

## [0.1.4] - 2026-04-20

### Added
- 🧪 Added `spec/arneis/samples_spec.rb` to dynamically validate all sample YAML files.
- 🛠️ Fixed missing dependencies for `CharactersCli` and `Character` in the main library entry point.

### Changed
- 🫘 refactor(cli): updated `arnectl list` to show asset counts (beans) first (e.g., `🫘 7: 2🎥 5📝`).
- 🔄 Migrated outdated sample YAML files to the current `VideoProject` schema.

## [0.1.3] - 2026-04-19

### Added
- 🥋 add character Yukihiro Takahashi (Taka Sensei) with 7 consistent images.
- 📸 added frontal and profile shots for all characters to improve AI replication.
- 📂 refactor(characters): migrated to self-contained folder structure (`<id>/character.yaml`).
- 💄 feat(cli): improved `arnectl characters list` format with better spacing.

## [0.1.2] - 2026-04-19

### Added
- 💎 add character Zenzile Mkhize with 5 consistent images.

## [0.1.1] - 2026-04-19

### Added
- ✨ feat(cli): overhaul `arnectl list` UI for better information density and aesthetics.
- 🔗 Added symlink detection with 🔗 icon and cyan coloring.
- 🎥 Added video and image counts (hidden if zero).
- 📏 Optimized space using dynamic path alignment and emoji tokenization.
- ✂️ Cropped project titles to 12 characters for a cleaner tabular layout.

## [0.1.0] - 2026-04-19

### Added
- 🚀 feat: implement LLM-driven `ffmpeg` montage generation in `VideoProject`.
- 📝 Created a comprehensive User Manual in `docs/user_manual.md`.
- 🔗 Linked the User Manual in `README.md`.
- 🔄 Added documentation for Resume and Resilience logic.
- ⚖️ Added documentation for Automated Evaluations (EVALs).
- 📊 Added detailed guide for interpreting the `arnectl status` output.
- 📂 Initialized `VERSION` and `CHANGELOG.md` files.
