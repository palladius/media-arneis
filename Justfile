# media-arneis - Justfile
BUNDLE := "bundle"

# Default task: list all commands
default:
        @just --list

# Install dependencies
install:
        {{BUNDLE}} install

# Run fast tests (unit-test)
test: unit-test

# Run quick unit tests (no LLM, fast)
unit-test:
        @echo "🟢 Running unit tests..."
        {{BUNDLE}} exec rspec --tag ~expensive --pattern "spec/arneis/**/*_spec.rb"

# Run integration tests (LLM-as-judge specs)
integration-test:
        @echo "🟢 Running integration tests..."
        {{BUNDLE}} exec rspec spec/integration/


# Run linter
lint:
        @echo "🟢 Running linter..."
        {{BUNDLE}} exec standardrb

# Run model verification
test-all-models:
        @echo "🟢 Verifying all models..."
        {{BUNDLE}} exec bin/test_models.rb

# Check for fake media files
check-fake-media:
        @echo "🟢 Checking for fake media..."
        {{BUNDLE}} exec bin/arnectl check-fake-media

# Archive projects with zero real media
autoarchive:
        @echo "🧹 Auto-archiving junk projects..."
        {{BUNDLE}} exec bin/arnectl cleanup
archive: autoarchive

# Helper to run arnectl from root
arnectl *args:
        @cd {{justfile_directory()}} && {{BUNDLE}} exec bin/arnectl {{args}}

list:
        just arnectl list


test-story:
        just arnectl apply data/samples/KidsStory/riccardo_story.yaml -f out/riccardo-manhouse/

# Run sticky PowerColon presentation test
test-power-colon:
        just arnectl apply data/samples/PowerColon/mock_presentation.yaml --output out/sticky-power-colon/ --force-clean

# Run full End-to-End expensive tests (no mocks)
e2e-test:
        @echo "🚀 Running expensive E2E tests..."
        ARNEIS_NO_MOCK=true {{BUNDLE}} exec rspec spec/e2e/


ricc-story:
        just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/just-ricc-story/

# timeout 300 bundle exec bin/arnectl apply data/samples/KidsStory/riccardo_story.yaml -o out/riccardo-consistent/
riccardo-consistent:
        just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/just-ricc-story/

status:
        @cd {{justfile_directory()}} && bin/git-worktree-statuses 


riccardo-cc:
        just arnectl generate CharacterImage -c riccardo -p "Riccardo as a cyberpunk hacker in a neon-lit Tokyo" --aspect_ratio 16:9 --open

alessandro-cc:
        just arnectl apply data/projects/alessandro_pokemon.yaml --open

sebastian-cc:
        just arnectl apply data/projects/sebastian_hotwheels.yaml  --open

alessandro-sebastian-cc:
        just arnectl apply data/projects/alessandro_sebastian_garden.yaml --open

ale-seby-cc:
        just arnectl apply data/projects/ale_seby_portrait.yaml --open

ale-seby-super-ninja-cc:
        just arnectl apply data/projects/ale_seby_super_ninja.yaml --open

# Generate a CharacterImage for Ale & Seby with a custom prompt (variadic)
ale-seby *prompt:
        bundle exec bin/arnectl generate CharacterImage -c alessandro,sebastian --open -p "{{prompt}}"

character-consistency-with-2:
        just arnectl generate CharacterImage -c riccardo,sebastian --aspect_ratio 4:3 --open -p "Riccardo is lifting his foot and Sebastian is holding his nose saying 'OMG that stinks!'"
