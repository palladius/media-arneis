# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
