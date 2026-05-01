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

arnectl *args:
	{{BUNDLE}} exec bin/arnectl {{args}}

#status:
#	just arnectl status

list:
	just arnectl list


test-story:
	just arnectl apply data/samples/KidsStory/riccardo_story.yaml -f out/riccardo-manhouse/
# Run expensive LLM integration tests (opt-in via ARNEIS_EXPENSIVE_TESTS=true)
test-expensive:
	{{BUNDLE}} exec bin/test_llm_expensive.rb


ricc-story:
	just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/just-ricc-story/

# timeout 300 bundle exec bin/arnectl apply data/samples/KidsStory/riccardo_story.yaml -o out/riccardo-consistent/
riccardo-consistent:
	just arnectl apply data/samples/KidsStory/riccardo_story.yaml --output out/riccardo-consistent/
status:
	bin/git-worktree-statuses 


riccardo-cc:
	arnectl generate CharacterImage -c riccardo -p "Riccardo as a cyberpunk hacker in a neon-lit Tokyo" --aspect_ratio 16:9 --open --eval


