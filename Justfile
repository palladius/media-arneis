# media-arneis - Justfile
BUNDLE := "bundle"

# Default task: list all commands
default:
        @just --list

# Install dependencies
install:
        {{BUNDLE}} install

# Run tests
test:
        @echo "🟢 Running tests..."
        {{BUNDLE}} exec rspec

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

test-expensive:
        {{BUNDLE}} exec bin/test_llm_expensive.rb

# Run full End-to-End expensive tests
test-e2e:
        @echo "🚀 Running expensive E2E tests..."
        ARNEIS_NO_MOCK=true {{BUNDLE}} exec rspec spec/e2e/

ricc-story:
        just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/just-ricc-story/

riccardo-consistent:
        just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/just-ricc-story/

status:
        @cd {{justfile_directory()}} && bin/git-worktree-statuses 

riccardo-cc:
        just arnectl apply data/projects/riccardo_cyberpunk.yaml --open

alessandro-cc:
        just arnectl apply data/projects/alessandro_pokemon.yaml --open

sebastian-cc:
        just arnectl apply data/projects/sebastian_hotwheels.yaml --open

alessandro-sebastian-cc:
        just arnectl apply data/projects/alessandro_sebastian_garden.yaml --open

ale-seby-cc:
        just arnectl apply data/projects/ale_seby_portrait.yaml --open

character-consistency-with-2:
        just arnectl apply data/projects/stinky_riccardo.yaml --open
