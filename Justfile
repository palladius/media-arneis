# media-arneis - Justfile
BUNDLE := "/home/riccardo/.rbenv/shims/bundle"

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

# Run the CLI
arnectl *args:
	{{BUNDLE}} exec bin/arnectl {{args}}
