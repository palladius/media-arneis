
Use Conductor extension to manage the BDD and SW dev

## Gemini models

* Do not use any Gemini model before 2.5 (no 2. and no 1.5). So 2.5 is the minimum that I want to use.
* `gemini-flash-latest` should be a good model to start with. It is cheap and fast.

## Software progress

* Use Conductor for new features. If they're not trivial, couple this with a GH Issue for external obesrvability.
* Use VERSION file containing the latest version and a CHANGELOG.md using SemVer and SemVer-git.
* Use gitmoji in commit messages and GH issues.

## Testing

* Tests must be executable from `just test` command, using common naming conventions, and run with the latest Ruby version (for now).
* All tests should pass before git commit and git push
