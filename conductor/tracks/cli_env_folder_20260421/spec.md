# Track Specification: CLI Improvements - ARNEIS_FOLDER and --media-folder

## Overview
This track improves the `arnectl` CLI usability by allowing the user to specify the target media folder via an environment variable or a command-line flag. This eliminates the need to always provide the folder as a positional argument.

## Functional Requirements
1. **Environment Variable Support:** The CLI MUST check for the `ARNEIS_FOLDER` environment variable. If set, it should be used as the default media folder.
2. **Command-Line Flag:** The CLI MUST support a `-f` or `--media-folder` flag to explicitly set the media folder.
3. **Precedence:** The precedence order for determining the media folder MUST be:
    1. Command-line flag (`-f` / `--media-folder`)
    2. Positional argument (if provided)
    3. Environment variable (`ARNEIS_FOLDER`)
4. **Clean CLI:** Update the help message and command signatures to reflect these changes.

## Acceptance Criteria
- [ ] `arnectl` works without a positional argument if `ARNEIS_FOLDER` is set.
- [ ] `arnectl -f <folder>` overrides `ARNEIS_FOLDER`.
- [ ] `arnectl status <folder>` (positional) still works and overrides `ARNEIS_FOLDER`.
- [ ] `arnectl --help` shows the new flag and explains the environment variable.

## Out of Scope
- Global configuration file (`~/.arneis.yaml`) is deferred to a future track.
