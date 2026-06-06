# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
