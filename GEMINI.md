
Use Conductor extension to manage the BDD and SW dev

## Gemini models

* Do **not** use any Gemini model before 2.5 (no 2. and no 1.5). So 2.5 is the minimum that I want to use.
* `gemini-flash-latest` should be a good model to start with. It is cheap and fast.

### GenMedia Recommended Models

* **Imagen (Nano Banana)**:
    * `gemini-2.5-flash-image`: Nano Banana.
    * `gemini-3-pro-image-preview`: Nano Banana Pro.
    * `gemini-3.1-flash-image-preview`: Nano Banana 2 (latest).
    * Note NanoBanana support creation and EDITING! It also supports character consistency across generations. 
    * Use Nano Banana skill for all of the above, and <nano-banana-ricc> for Riccardo character consistency.
* **Veo (Video)**:
    * `veo-2.0-generate-001`: Default Veo 2 model.
    * `veo-3.0-generate-001`: Newest Veo 3 with ambient audio and voice-overs.
* **Lyria (Music)**:
    * `lyria-002`: Standard for music.
    * `lyria-3-clip-preview`: ~30sec clips with lyrics.
    * `lyria-3-pro-preview`: ~2min high-quality with lyrics.
* **Chirp (Speech)**:
    * `chirp_2`: Highly recommended for most use cases (GA).
    * `chirp_3`: Latest speech model, GA in US and EU.

## Software progress

* Use Conductor for new features. If they're not trivial, couple this with a GH Issue for external obesrvability.
* Use `VERSION` file containing the latest version and a `CHANGELOG.md` using SemVer and SemVer-git.
* Use gitmoji in commit messages and GH issues.
* Some activities take time! Prepend `timeout 60` if you foresee an activity lasting more than 60s.
    * Use a Gemini cLI **SubAgent** when video/audio generation is involved.
* Do not break POLA - Principles of Least Astonishment.

## Git development

* Use <git worktree> for multi-agent parallel working on same computer.
* For every feature being worke dby conductor, create a feature branch called "YYYYMM-featurename".
* move to `~/git/media-arneis/workstree/BRANCHNAME` and do the changes there.
* When happy, do the usual VERSION/CHANGELOG change.
* [a few times] Ensure user is happy, and confirm with user when its DONE. Iterate until user is happy.
* Now user is happy: final commit/version/changelog.
* merge with main.
* delete the branch.
* either exit or ask user what to do.

**Note**: conductor changes should be applied to MAIN too (if this is difficult, maybe you can commit/merge IMMEDIATELY after confirming the new task or task execution). This ensure we dont have two conductor threads working on same job...

## Ruby

* Use async. Read these docs from Carmine Paolino: https://rubyllm.com/async/ and https://paolino.me/async-ruby-is-the-future/


## Testing

* Tests must be executable from `just test` command, using common naming conventions, and run with the latest Ruby version (for now).
* All tests should pass before `git commit` and `git push`.
* If you're testing something like "test_if_llm_works.rb", do NOT add it to git. To make sure you don't, use .gitignore for these files.
    * Maybe use regexes like tmp_*.rb or test_llm_*.rb, etc. to ignore them.


* Keep all python files under util/ . Note they are supposed to be "external utilities" whereas ruby cant execute that logic for lack of good libraries.
* Do NOT delete files without confirming prior with user.
