# media-arneis - Justfile
BUNDLE := "bundle"

# Default task: list all commands
default:
        @just --list

# Install dependencies
install:
        {{BUNDLE}} install

# Run fast tests (unit tests)
test:
        @echo "🟢 Running fast tests..."
        {{BUNDLE}} exec rspec --tag ~expensive

# Run long tests (e2e and expensive tests)
long-tests:
        @echo "🟢 Running long tests..."
        {{BUNDLE}} exec rspec --tag expensive

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
# Run expensive LLM integration tests (opt-in via ARNEIS_EXPENSIVE_TESTS=true)
test-expensive:
        {{BUNDLE}} exec bin/test_llm_expensive.rb

# Run full End-to-End expensive tests
test-e2e:
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
