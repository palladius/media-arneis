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

# Running safe CLI arneis with limit of 300seconds
arnectl *args:
	@white "timeout 300 {{BUNDLE}} exec bin/arnectl {{args}}"
	@timeout 300 {{BUNDLE}} exec bin/arnectl {{args}}

status:
	just arnectl status

list:
	just arnectl list


test-story:
	just arnectl apply data/samples/KidsStory/riccardo_story.yaml -f out/riccardo-manhouse/
# Run expensive LLM integration tests (opt-in via ARNEIS_EXPENSIVE_TESTS=true)
test-expensive:
	{{BUNDLE}} exec bin/test_llm_expensive.rb


ricc-story:
	just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/just-ricc-story/

riccardo-consistent:
	just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/riccardo-consistent/.