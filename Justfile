# media-arneis - Justfile
BUNDLE := "~/.rbenv/shims/bundle"

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

# Run the CLI
arnectl *args:
	# Running safe arneis with limit of 60seconds
	timeout 60 {{BUNDLE}} exec bin/arnectl {{args}}

status:
	just arnectl status